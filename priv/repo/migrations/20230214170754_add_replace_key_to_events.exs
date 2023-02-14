defmodule Nex.Repo.Migrations.AddReplaceKeyToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :replace_key, :string
    end
    alter table(:tags) do
      modify :value, :string, null: true, from: :string
    end

    index_conditions = """
    kind IN (0, 3, 41)
    OR (kind >= 10000 AND kind < 20000)
    OR (kind >= 30000 AND kind < 40000)
    """
    create index(:events, [:pubkey, :kind, :replace_key], where: index_conditions)
  end
end
