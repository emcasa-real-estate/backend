defmodule ReWeb.Resolvers.Calendars do
  @moduledoc """
  Resolver module for calendars
  """
  import Absinthe.Resolution.Helpers, only: [on_load: 2]

  alias Re.{
    Calendars,
    Listings
  }

  def tour_options(_, _) do
    now = Timex.now()

    {:ok,
     [
       now |> Timex.shift(days: 3) |> Timex.shift(hours: 2),
       now |> Timex.shift(days: 4) |> Timex.shift(hours: 2),
       now |> Timex.shift(days: 3) |> Timex.shift(hours: 4),
       now |> Timex.shift(days: 4) |> Timex.shift(hours: 4)
     ]}
  end

  def schedule_tour(%{input: params}, %{context: %{current_user: current_user}}) do
    with :ok <- Bodyguard.permit(Calendars, :schedule_tour, current_user, %{}),
         params <- Map.put(params, :user_id, current_user.id) do
      Calendars.schedule_tour(params)
    end
  end

  def listings(tour_appointment, _, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(Listings, {:listing, %{has_admin_rights: true}}, tour_appointment)
    |> on_load(fn loader ->
      {:ok,
       Dataloader.get(loader, Listings, {:listing, %{has_admin_rights: true}}, tour_appointment)}
    end)
  end
end
