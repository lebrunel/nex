defmodule Nex.RateLimiter do
  @moduledoc """
  Rate limiter module.
  """

  @typedoc """
  A limit is a tuple containing the scale period (ms) and the limit.
  """
  @type limit() :: {scale :: integer(), limit :: integer()}

  @doc """
  Iterates over the given list of limits and checks each against the specified
  action ID.
  """
  @spec limit(String.t(), list(limit())) :: :ok | {:deny, limit()} | {:error, term()}
  def limit(_id, []), do: :ok
  def limit(id, [{scale, limit} | limits]) do
    with {:allow, _count} <- Hammer.check_rate("#{id}:#{scale}", scale * 1000, limit) do
      limit(id, limits)
    else
      {:deny, _limit} -> {:deny, {scale, limit}}
    end
  end

end
