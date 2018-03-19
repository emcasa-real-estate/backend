defmodule ReWeb.ListingControllerTest do
  use ReWeb.ConnCase

  alias Re.{
    Address,
    Listing
  }

  alias ReWeb.Guardian

  import Re.Factory

  @valid_attrs %{
    type: "Casa",
    score: 3,
    floor: "H1",
    complement: "basement",
    bathrooms: 2,
    description: "some content",
    price: 1_000_000,
    property_tax: 500.00,
    maintenance_fee: 300.00,
    rooms: 4,
    area: 140,
    garage_spots: 3,
    suites: 1,
    dependencies: 1,
    has_elevator: true,
    is_exclusive: true
  }
  @valid_address_attrs %{
    street: "A Street",
    street_number: "100",
    neighborhood: "A Neighborhood",
    city: "A City",
    state: "ST",
    postal_code: "12345-678",
    lat: "25",
    lng: "25"
  }
  @invalid_attrs %{
    score: 7,
    bathrooms: -1,
    price: -1,
    property_tax: -500.00,
    maintenance_fee: -300.00,
    rooms: -1,
    area: -1,
    garage_spots: -1,
    suites: -1,
    dependencies: -1
  }

  setup %{conn: conn} do
    conn = put_req_header(conn, "accept", "application/json")
    admin_user = insert(:user, email: "admin@email.com", role: "admin")
    user_user = insert(:user, email: "user@email.com", role: "user")

    {:ok,
     unauthenticated_conn: conn,
     admin_user: admin_user,
     user_user: user_user,
     admin_conn: login_as(conn, admin_user),
     user_conn: login_as(conn, user_user)}
  end

  describe "index" do
    test "admin user", %{admin_conn: conn, admin_user: user} do
      listing = insert(:listing, address: build(:address), user: user)

      conn = get(conn, listing_path(conn, :index))

      listings = json_response(conn, 200)["listings"]
      retrieved_listing = List.first(listings)
      assert retrieved_listing["description"] == listing.description
    end

    test "not admin user", %{user_conn: conn, user_user: user} do
      listing = insert(:listing, address: build(:address), user: user)

      conn = get(conn, listing_path(conn, :index))

      listings = json_response(conn, 200)["listings"]
      retrieved_listing = List.first(listings)
      assert retrieved_listing["description"] == listing.description
    end

    test "paginated query", %{admin_conn: conn, admin_user: user} do
      insert_list(5, :listing, address: insert(:address), user: user)

      conn = get(conn, listing_path(conn, :index, %{page_size: 2, page: 1}))

      assert [_, _] = json_response(conn, 200)["listings"]
      assert 1 == json_response(conn, 200)["page_number"]
      assert 2 == json_response(conn, 200)["page_size"]
      assert 3 == json_response(conn, 200)["total_pages"]
      assert 5 == json_response(conn, 200)["total_entries"]

      conn = get(conn, listing_path(conn, :index, %{page_size: 2, page: 2}))

      assert [_, _] = json_response(conn, 200)["listings"]
      assert 2 == json_response(conn, 200)["page_number"]
      assert 2 == json_response(conn, 200)["page_size"]
      assert 3 == json_response(conn, 200)["total_pages"]
      assert 5 == json_response(conn, 200)["total_entries"]
    end
  end

  describe "show" do
    test "resource for admin user", %{admin_conn: conn, admin_user: user} do
      image = insert(:image)
      listing = insert(:listing, images: [image], address: build(:address), user: user)
      conn = get(conn, listing_path(conn, :show, listing))

      assert json_response(conn, 200)["listing"] ==
               %{
                 "id" => listing.id,
                 "type" => listing.type,
                 "description" => listing.description,
                 "price" => listing.price,
                 "property_tax" => listing.property_tax,
                 "maintenance_fee" => listing.maintenance_fee,
                 "floor" => listing.floor,
                 "rooms" => listing.rooms,
                 "bathrooms" => listing.bathrooms,
                 "area" => listing.area,
                 "garage_spots" => listing.garage_spots,
                 "matterport_code" => listing.matterport_code,
                 "suites" => listing.suites,
                 "dependencies" => listing.dependencies,
                 "has_elevator" => listing.has_elevator,
                 "is_exclusive" => listing.is_exclusive,
                 "is_active" => listing.is_active,
                 "user_id" => listing.user_id,
                 "images" => [
                   %{
                     "id" => image.id,
                     "filename" => image.filename,
                     "position" => image.position
                   }
                 ],
                 "address" => %{
                   "street" => listing.address.street,
                   "street_number" => listing.address.street_number,
                   "neighborhood" => listing.address.neighborhood,
                   "city" => listing.address.city,
                   "state" => listing.address.state,
                   "postal_code" => listing.address.postal_code,
                   "lat" => listing.address.lat,
                   "lng" => listing.address.lng
                 }
               }
    end

    test "resource for non user", %{user_conn: conn, admin_user: user} do
      address = insert(:address)
      image = insert(:image)
      listing = insert(:listing, images: [image], address: address, user: user)
      conn = get(conn, listing_path(conn, :show, listing))

      assert json_response(conn, 200)["listing"] ==
               %{
                 "id" => listing.id,
                 "type" => listing.type,
                 "description" => listing.description,
                 "price" => listing.price,
                 "property_tax" => listing.property_tax,
                 "maintenance_fee" => listing.maintenance_fee,
                 "floor" => listing.floor,
                 "rooms" => listing.rooms,
                 "bathrooms" => listing.bathrooms,
                 "area" => listing.area,
                 "garage_spots" => listing.garage_spots,
                 "matterport_code" => listing.matterport_code,
                 "suites" => listing.suites,
                 "dependencies" => listing.dependencies,
                 "has_elevator" => listing.has_elevator,
                 "is_exclusive" => listing.is_exclusive,
                 "is_active" => listing.is_active,
                 "user_id" => listing.user_id,
                 "images" => [
                   %{
                     "id" => image.id,
                     "filename" => image.filename,
                     "position" => image.position
                   }
                 ],
                 "address" => %{
                   "street" => listing.address.street,
                   "street_number" => listing.address.street_number,
                   "neighborhood" => listing.address.neighborhood,
                   "city" => listing.address.city,
                   "state" => listing.address.state,
                   "postal_code" => listing.address.postal_code,
                   "lat" => listing.address.lat,
                   "lng" => listing.address.lng
                 }
               }
    end

    test "do not show inactive listing for non admin user", %{user_conn: conn} do
      image = insert(:image)

      listing = insert(:listing, images: [image], address: build(:address), is_active: false)

      conn = get(conn, listing_path(conn, :show, listing))
      json_response(conn, 404)
    end

    test "do not show inactive listing for unauthenticated user", %{unauthenticated_conn: conn} do
      image = insert(:image)

      listing = insert(:listing, images: [image], address: build(:address), is_active: false)

      conn = get(conn, listing_path(conn, :show, listing))
      json_response(conn, 404)
    end

    test "show inactive listing for admin user", %{admin_conn: conn} do
      image = insert(:image)

      listing = insert(:listing, images: [image], address: build(:address), is_active: false)

      conn = get(conn, listing_path(conn, :show, listing))
      json_response(conn, 200)
    end

    test "show inactive listing for owner user", %{user_conn: conn, user_user: user} do
      image = insert(:image)

      listing = insert(:listing, images: [image], address: build(:address), is_active: false, user_id: user.id)

      conn = get(conn, listing_path(conn, :show, listing))
      json_response(conn, 200)
    end

    test "renders page not found when id is nonexistent", %{admin_conn: conn} do
      conn = get(conn, listing_path(conn, :show, -1))
      json_response(conn, 404)
    end

    test "list listing for unauthenticated requests even if not authenticated", %{
      unauthenticated_conn: conn,
      admin_user: user
    } do
      image = insert(:image)
      listing = insert(:listing, images: [image], address: build(:address), user: user)

      conn = get(conn, listing_path(conn, :show, listing))
      json_response(conn, 200)
    end

    test "do not show inactive image", %{
      unauthenticated_conn: conn,
      admin_user: user
    } do
      %{id: id1} = image1 = insert(:image, position: 1)
      %{id: id2} = image2 = insert(:image, position: 2)
      image3 = insert(:image, is_active: false)

      listing =
        insert(:listing, images: [image1, image2, image3], address: build(:address), user: user)

      conn = get(conn, listing_path(conn, :show, listing))
      response = json_response(conn, 200)
      assert [%{"id" => ^id1}, %{"id" => ^id2}] = response["listing"]["images"]
    end
  end

  describe "edit" do
    test "edits chosen resource", %{admin_conn: conn, admin_user: user} do
      image = insert(:image)
      listing = insert(:listing, images: [image], address: build(:address), user: user)
      conn = get(conn, listing_path(conn, :edit, listing))

      assert json_response(conn, 200)["listing"] ==
               %{
                 "id" => listing.id,
                 "type" => listing.type,
                 "complement" => listing.complement,
                 "description" => listing.description,
                 "price" => listing.price,
                 "property_tax" => listing.property_tax,
                 "maintenance_fee" => listing.maintenance_fee,
                 "floor" => listing.floor,
                 "rooms" => listing.rooms,
                 "bathrooms" => listing.bathrooms,
                 "area" => listing.area,
                 "garage_spots" => listing.garage_spots,
                 "score" => listing.score,
                 "matterport_code" => listing.matterport_code,
                 "suites" => listing.suites,
                 "dependencies" => listing.dependencies,
                 "has_elevator" => listing.has_elevator,
                 "is_exclusive" => listing.is_exclusive,
                 "is_active" => listing.is_active,
                 "images" => [
                   %{
                     "id" => image.id,
                     "filename" => image.filename,
                     "position" => image.position
                   }
                 ],
                 "address" => %{
                   "street" => listing.address.street,
                   "street_number" => listing.address.street_number,
                   "neighborhood" => listing.address.neighborhood,
                   "city" => listing.address.city,
                   "state" => listing.address.state,
                   "postal_code" => listing.address.postal_code,
                   "lat" => listing.address.lat,
                   "lng" => listing.address.lng
                 }
               }
    end

    test "edit if listing belongs to user", %{user_conn: conn, user_user: user} do
      image = insert(:image)
      listing = insert(:listing, images: [image], address: build(:address), user: user)
      conn = get(conn, listing_path(conn, :edit, listing))
      assert json_response(conn, 403)
      # assert json_response(conn, 200)
    end

    test "fails if listing does not belong to user", %{user_conn: conn, admin_user: user} do
      image = insert(:image)
      listing = insert(:listing, images: [image], address: build(:address), user: user)
      conn = get(conn, listing_path(conn, :edit, listing))
      assert json_response(conn, 403)
    end

    test "renders page not found when id is nonexistent", %{admin_conn: conn} do
      conn = get(conn, listing_path(conn, :edit, -1))
      json_response(conn, 404)
    end

    test "does not list listing for unauthenticated requests even if not authenticated", %{
      unauthenticated_conn: conn,
      admin_user: user
    } do
      image = insert(:image)
      listing = insert(:listing, images: [image], address: build(:address), user: user)

      conn = get(conn, listing_path(conn, :edit, listing))
      json_response(conn, 401)
    end
  end

  describe "create" do
    test "creates and renders resource as admin", %{admin_conn: conn, admin_user: user} do
      conn =
        post(
          conn,
          listing_path(conn, :create),
          listing: @valid_attrs,
          address: @valid_address_attrs
        )

      response = json_response(conn, 201)
      assert response["listing"]["id"]
      assert listing = Repo.get_by(Listing, @valid_attrs)
      assert listing.user_id == user.id
    end

    test "creates and renders resource as user", %{user_conn: conn, user_user: user} do
      conn =
        post(conn, listing_path(conn, :create), %{
          listing: @valid_attrs,
          address: @valid_address_attrs
        })

      json_response(conn, 201)
      assert listing = Repo.get_by(Listing, @valid_attrs)
      assert listing.user_id == user.id
    end

    test "creates and renders resource with existing address", %{admin_conn: conn} do
      insert(:address, @valid_address_attrs)

      conn =
        post(
          conn,
          listing_path(conn, :create),
          listing: @valid_attrs,
          address: @valid_address_attrs
        )

      response = json_response(conn, 201)
      assert response["listing"]["id"]
      assert Repo.get_by(Listing, @valid_attrs)
      assert length(Repo.all(Address)) == 1
    end

    test "does not create resource and renders errors when data is invalid", %{admin_conn: conn} do
      conn =
        post(conn, listing_path(conn, :create), %{
          listing: @invalid_attrs,
          address: @valid_address_attrs
        })

      assert json_response(conn, 422)["errors"] != %{}
      assert Repo.all(Listing) == []
    end

    test "does not create resource when user is not authenticated", %{unauthenticated_conn: conn} do
      conn =
        post(conn, listing_path(conn, :create), %{
          listing: @valid_attrs,
          address: @valid_address_attrs
        })

      json_response(conn, 401)
      refute Repo.get_by(Listing, @valid_attrs)
    end
  end

  describe "update" do
    test "updates and renders chosen resource when data is valid", %{
      admin_conn: conn,
      admin_user: user
    } do
      listing = insert(:listing, address: build(:address), user: user)

      conn =
        put(
          conn,
          listing_path(conn, :update, listing),
          id: listing.id,
          listing: @valid_attrs,
          address: @valid_address_attrs
        )

      assert json_response(conn, 200)["listing"]["id"]
      assert Repo.get_by(Listing, @valid_attrs)
    end

    test "does not update chosen resource and renders errors when data is invalid", %{
      admin_conn: conn,
      admin_user: user
    } do
      listing = insert(:listing, address: build(:address), user: user)

      conn =
        put(conn, listing_path(conn, :update, listing), %{
          id: listing.id,
          listing: @invalid_attrs,
          address: @valid_address_attrs
        })

      assert json_response(conn, 422)["errors"] != %{}
    end

    test "does not update resource when user is not authenticated", %{unauthenticated_conn: conn} do
      listing = insert(:listing, address: build(:address))

      conn =
        put(
          conn,
          listing_path(conn, :update, listing),
          id: listing.id,
          listing: @valid_attrs,
          address: @valid_address_attrs
        )

      assert json_response(conn, 401)
      refute Repo.get_by(Listing, @valid_attrs)
    end

    test "update resource when listing belongs to user", %{user_conn: conn, user_user: user} do
      listing = insert(:listing, address: build(:address), user: user)

      conn =
        put(
          conn,
          listing_path(conn, :update, listing),
          id: listing.id,
          listing: @valid_attrs,
          address: @valid_address_attrs
        )

      assert json_response(conn, 403)
      # assert json_response(conn, 200)
      # assert Repo.get_by(Listing, @valid_attrs)
    end

    test "does not update resource when listing doesn't belong to user", %{
      user_conn: conn,
      admin_user: user
    } do
      listing = insert(:listing, address: build(:address), user: user)

      conn =
        put(
          conn,
          listing_path(conn, :update, listing),
          id: listing.id,
          listing: @valid_attrs,
          address: @valid_address_attrs
        )

      assert json_response(conn, 403)
      refute Repo.get_by(Listing, @valid_attrs)
    end
  end

  describe "delete" do
    test "deletes chosen resource", %{admin_conn: conn} do
      listing = insert(:listing)
      conn = delete(conn, listing_path(conn, :delete, listing))
      assert response(conn, 204)
      assert listing = Repo.get(Listing, listing.id)
      refute listing.is_active
    end

    test "does not delete resource when user is not authenticated", %{unauthenticated_conn: conn} do
      listing = insert(:listing)
      conn = delete(conn, listing_path(conn, :delete, listing))
      assert response(conn, 401)
      assert listing = Repo.get(Listing, listing.id)
      assert listing.is_active
    end

    test "delete resource when listing belongs to user", %{user_conn: conn, user_user: user} do
      listing = insert(:listing, user: user)
      conn = delete(conn, listing_path(conn, :delete, listing))
      assert response(conn, 403)
      # assert response(conn, 204)
      # assert listing = Repo.get(Listing, listing.id)
      # refute listing.is_active
    end

    test "doest not delete resource when listing doesn't belong to user", %{
      user_conn: conn,
      admin_user: user
    } do
      listing = insert(:listing, user: user)
      conn = delete(conn, listing_path(conn, :delete, listing))
      assert response(conn, 403)
      assert listing = Repo.get(Listing, listing.id)
      assert listing.is_active
    end
  end

  describe "toggle" do
    test "deactivate listing for admin user", %{admin_conn: conn} do
      listing = insert(:listing, address: build(:address), is_active: true)
      conn = put(conn, listing_listing_path(conn, :toggle, listing), id: listing.id)
      assert response(conn, 200)
      assert listing = Repo.get(Listing, listing.id)
      refute listing.is_active
    end

    test "activate listing for admin user", %{admin_conn: conn} do
      listing = insert(:listing, address: build(:address), is_active: false)
      conn = put(conn, listing_listing_path(conn, :toggle, listing), id: listing.id)
      assert response(conn, 200)
      assert listing = Repo.get(Listing, listing.id)
      assert listing.is_active
    end

    test "does not deactivate listing for non admin user", %{user_conn: conn} do
      listing = insert(:listing, address: build(:address), is_active: true)
      conn = put(conn, listing_listing_path(conn, :toggle, listing), id: listing.id)
      assert response(conn, 403)
      assert listing = Repo.get(Listing, listing.id)
      assert listing.is_active
    end

    test "does not activate listing for non admin user", %{user_conn: conn} do
      listing = insert(:listing, address: build(:address), is_active: false)
      conn = put(conn, listing_listing_path(conn, :toggle, listing), id: listing.id)
      assert response(conn, 403)
      assert listing = Repo.get(Listing, listing.id)
      refute listing.is_active
    end

    test "does not deactivate listing for unauthenticated user", %{unauthenticated_conn: conn} do
      listing = insert(:listing, address: build(:address), is_active: true)
      conn = put(conn, listing_listing_path(conn, :toggle, listing), id: listing.id)
      assert response(conn, 401)
      assert listing = Repo.get(Listing, listing.id)
      assert listing.is_active
    end

    test "does not activate listing for unauthenticated user", %{unauthenticated_conn: conn} do
      listing = insert(:listing, address: build(:address), is_active: false)
      conn = put(conn, listing_listing_path(conn, :toggle, listing), id: listing.id)
      assert response(conn, 401)
      assert listing = Repo.get(Listing, listing.id)
      refute listing.is_active
    end
  end
end
