defmodule Re.Addresses.District do
  @moduledoc """
  Model for districts.
  """
  use Ecto.Schema

  import Ecto.Changeset

  schema "districts" do
    field :state, :string
    field :city, :string
    field :name, :string
    field :description, :string

    has_many :addresses, Re.Address

    timestamps()
  end

  @required ~w(state city name)a
  @optional ~w(description)a

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @optional ++ @required)
    |> validate_required(@required)
  end
end
