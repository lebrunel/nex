defmodule Nex.Handler do
  @moduledoc """
  Handler behaviour.

  Messages received to the `Nex.Socket` handler are routed to different
  modules that implement this behaviour.
  """
  alias Nex.Socket

  @doc """
  Callback for handling message items. Must return a `t:WebSock.handle_result/0`.
  """
  @callback handle_item(term(), Socket.t()) :: WebSock.handle_result()

end
