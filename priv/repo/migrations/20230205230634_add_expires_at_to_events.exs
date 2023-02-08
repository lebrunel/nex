defmodule Nex.Repo.Migrations.AddExpiresAtToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :expires_at, :integer
    end

    create index(:events, [:expires_at])
  end
end
