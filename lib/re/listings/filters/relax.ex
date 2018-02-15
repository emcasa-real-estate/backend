defmodule Re.Listings.Filters.Relax do

  alias Re.Listings.Filter

  defguardp is_not_nil(value) when not is_nil(value)

  def price(params) do
    params
    |> Filter.cast()
    |> max_price()
    |> min_price()
  end

  defp max_price(%{max_price: max_price} = params) when is_not_nil(max_price) do
    Map.update(params, :max_price, 0, &(trunc(&1 * 1.1)))
  end
  defp max_price(params), do: params

  defp min_price(%{min_price: min_price} = params) when is_not_nil(min_price) do
    Map.update(params, :min_price, 0, &(trunc(&1 * 0.9)))
  end
  defp min_price(params), do: params

end
