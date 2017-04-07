defmodule Archivebot.Record do
  use Ecto.Schema

  import Ecto.Changeset

  schema "records" do
    field :user_id, :string, null: false
    field :username, :string, null: false
    field :timestamp, :utc_datetime, null: false
    field :channel, :string, null: false
    field :channel_id, :string, null: false
    field :message, :string, null: false

    timestamps()
  end

  @all_fields [:user_id, :timestamp, :channel, :message, :username, :channel_id]
  @required_fields [:user_id, :timestamp, :channel, :message, :username, :channel_id]

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @all_fields)
    |> validate_required(@required_fields)
  end
end