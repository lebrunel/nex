defmodule Nex.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :nex,
    adapter: Ecto.Adapters.Postgres

end
