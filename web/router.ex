defmodule Re.Router do
  use Re.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", Re do
    pipe_through :api
  end
end
