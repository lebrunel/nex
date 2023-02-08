defmodule Nex.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :nid, :bigserial, primary_key: true
      add :id, :string, size: 64, null: false
      add :pubkey, :string, size: 64, null: false
      add :created_at, :integer, null: false
      add :kind, :integer, null: false
      add :tags, :map, null: false
      add :content, :text, null: false
      add :sig, :string, size: 128, null: false

      timestamps type: :utc_datetime, updated_at: false
    end

    create unique_index(:events, [:id])
    create index(:events, [:pubkey])
    create index(:events, [:created_at])
    create index(:events, [:kind])
  end
end
