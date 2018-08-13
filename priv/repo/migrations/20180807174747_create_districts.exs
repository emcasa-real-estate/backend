defmodule Re.Repo.Migrations.CreateDistricts do
  use Ecto.Migration

  def up do
    create table(:districts) do
      add :name, :string
      add :state, :string
      add :city, :string
      add :description, :string

      timestamps()
    end

    alter table(:addresses) do
      add :district_id, references(:districts)
    end

    flush()

    import Ecto.Query

    (
      from a in Re.Address,
      where: not is_nil(a.neighborhood),
      distinct: a.neighborhood
    )
    |> Re.Repo.all()
    |> Enum.each(fn address ->
      %Re.Addresses.District{}
      |> Re.Addresses.District.changeset(%{name: address.neighborhood, city: address.city, state: address.state})
      |> Re.Repo.insert()
    end)

    flush()

    Re.Address
    |> Re.Repo.all()
    |> Enum.each(fn address ->
      case Re.Repo.get_by(Re.Addresses.District, name: address.neighborhood) do
          nil ->
            IO.puts "shouldn't be here"
            {:ok, %{id: id}} =
              %Re.Addresses.District{}
              |> Re.Addresses.District.changeset(%{name: address.neighborhood, city: address.city, state: address.state})
              |> Re.Repo.insert()

            address
            |> Re.Address.changeset(%{district_id: id})
            |> Re.Repo.update()
          %{id: id} ->
            address
            |> Re.Address.changeset(%{district_id: id})
            |> Re.Repo.update()
      end
    end)

    flush()

    alter table(:addresses) do
      remove :neighborhood
    end
  end

  def down do
    alter table(:addresses) do
      add :neighborhood, :string
    end

    flush()

    Re.Addresses.District
    |> Re.Repo.all()
    |> Enum.each(fn neighborhood ->
      name = neighborhood.name

      neighborhood
      |> Re.Repo.preload(:addresses)
      |> Map.get(:addresses)
      |> Enum.each(
        fn address ->
          address
          |> Re.Address.changeset(%{neighborhood: name})
          |> Re.Repo.update()
      end)
    end)

    flush()

    alter table(:addresses) do
      remove :district_id
    end

    flush()

    drop table(:districts)
  end
end
