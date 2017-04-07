defmodule Archivebot.Repo.Migrations.AddRecordsTable do
  use Ecto.Migration

  def change do
    create table(:records) do
      add :user_id, :string, null: false
      add :username, :string, null: false
      add :timestamp, :utc_datetime, null: false
      add :channel, :string, null: false
      add :channel_id, :string, null: false
      add :message, :text, null: false

      timestamps()
    end
  end
end
