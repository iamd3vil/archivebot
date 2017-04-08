defmodule Archivebot do
  use Slack
  require Logger
  import Ecto.Query
  alias Archivebot.{Record, Repo}

  def handle_connect(slack, _) do
    Logger.info "[*] Connected to slack."
    bot_user_id = slack.me.id
    re = Regex.compile!("<@#{bot_user_id}>\s+/search\s+(?<query>.+)")
    {:ok, %{bot_regex: re}}
  end

  def handle_event(%{type: "message", user: user_id}, %{me: %{id: user_id}}, state) do
    {:ok, state}
  end
  def handle_event(message = %{type: "message", channel: "D" <> _ = channel}, slack, state) do
    case check_if_bot_mentioned(message, state) do
      {true, query} ->
        search_db(query)
        |> case do
          [] -> send_message("Sorry. I couldn't find anything for search query: `#{query}`.", channel, slack)
          rows ->
            Logger.debug "Search rows: #{inspect rows}"
            response = make_search_response(rows)
            send_message(response, channel, slack)
        end
      _ -> 
        send_message("Hey. I got a message from you!. Text: #{message.text}", message.channel, slack)
    end
    {:ok, state}
  end
  def handle_event(message = %{type: "message", user: _user_id, channel: channel}, slack, state) do
    Logger.info "Channel: #{message.channel}, timestamp: #{message.ts}, message: #{message.text}"
    case check_if_bot_mentioned(message, state) do
      {true, query} ->
        search_db(query)
        |> case do
          [] -> send_message("Sorry. I couldn't find anything for search query: `#{query}`.", channel, slack)
          rows ->
            Logger.debug "Search rows: #{inspect rows}"
            response = make_search_response(rows)
            send_message(response, channel, slack)
        end
      _ -> 
        :ok = dump_in_db(message)
    end
    {:ok, state}
  end
  def handle_event(_, _, state) do
    {:ok, state}
  end

  def handle_info({:message, text, channel}, slack, state) do
    IO.puts "Sending your message, captain!"

    send_message(text, channel, slack)

    {:ok, state}
  end
  def handle_info(_, _, state), do: {:ok, state}

  defp dump_in_db(message) do
    username = message.user |> get_username()
    channel = message.channel |> get_channel_name()
    timestamp = 
      extract_float(message.ts) * 10_00_000
      |> convert_to_int
      |> DateTime.from_unix!(:microsecond)

    changeset = %Record{}
    |> Record.changeset(%{
      user_id: message.user,
      username: username,
      channel: channel,
      channel_id: message.channel,
      timestamp: timestamp,
      message: message.text
    })

    if changeset.valid? == true do
      Repo.insert(changeset)
      |> case do
        {:ok, _} -> :ok
        {:error, _} -> Logger.warn "Got error inserting."
      end
    end
  end

  defp check_if_bot_mentioned(%{text: text}, %{bot_regex: bot_regex}) do
    case Regex.named_captures(bot_regex, text) do
      nil -> false
      %{"query" => query} -> {true, query}
    end
  end

  defp get_username(user_id) do
    Slack.Web.Users.info(user_id)
    |> Map.get("user")
    |> Map.get("name")
  end

  defp get_channel_name("C" <> _ = channel_id) do
    Slack.Web.Channels.info(channel_id)
    |> Map.get("channel")
    |> Map.get("name")
  end

  defp get_channel_name("G" <> _ = channel_id) do
    Slack.Web.Groups.info(channel_id)
    |> Map.get("group")
    |> Map.get("name")
  end

  defp extract_float(float) do
    {num, _} = Float.parse(float)
    num
  end

  defp convert_to_int(float) do
    bin = to_string(float)
    {num, _} = Integer.parse(bin)
    num
  end

  # Searches db using postgresql full text search
  defp search_db(query) do
    search_query =
      query
      |> String.split(" ")
      |> Enum.join("&")

    q = from r in Record, 
        where: fragment("to_tsvector(?) @@ to_tsquery(?)", r.message, ^search_query), 
        select: map(r, [:id, :username, :channel, :timestamp, :message])
    Repo.all(q)
  end

  defp make_search_response(search_rows) do
    response_string = """
    These are thse results I found.

    <%= for row <- search_rows do %>
    <%= row.id %>. Posted by `<%= row.username %>` at `<%= DateTime.to_iso8601(row.timestamp) %>` in channel: `<%= row.channel %>`
    
        <%= row.message %>
    <% end %>
    """
    EEx.eval_string(response_string, [search_rows: search_rows])
  end
end
