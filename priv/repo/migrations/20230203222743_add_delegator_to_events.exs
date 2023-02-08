defmodule Nex.Repo.Migrations.AddDelegatorToEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      add :delegator, :string, size: 64
    end

    create index(:events, [:delegator])
  end
end
