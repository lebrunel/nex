defmodule Nex.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags, primary_key: false) do
      add :nid, :bigserial, primary_key: true
      add :name, :string, null: false
      add :value, :string, null: false
      add :event_nid, references(:events, column: :nid, on_delete: :delete_all)
    end

    create index(:tags, [:name, :value])
  end
end
