defmodule TestPlug do
  import Plug.Conn

  def init(opts \\ []) do
   opts
  end

  def call(conn, _args) do
    resp(conn, 401, "wat")
  end

end
