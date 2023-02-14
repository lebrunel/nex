defmodule Nex.Messages.DBTag do
  @moduledoc """
  Nex DBTag schema.

  Nex stores the first two fields of every tag as a seperate row in the
  database to enable more perfomant querying on tags.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias Nex.Messages.Event

  @primary_key {:nid, :id, autogenerate: true}
  schema "tags" do
    field :name, :string
    field :value, :string
    belongs_to :event, Event, foreign_key: :event_nid, references: :nid
  end

  @doc """
  Returns a changeset from the given params.
  """
  @spec changeset(Ecto.Schema.t(), map() | list(String.t())) :: Ecto.Changeset.t()
  def changeset(tag, params \\ %{}) do
    tag
    |> cast(params, [:name, :value])
    |> validate_required([:name])
  end

end
