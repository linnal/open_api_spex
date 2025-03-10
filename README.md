# Open API Spex
[![Build Status](https://travis-ci.com/open-api-spex/open_api_spex.svg?branch=master)](https://travis-ci.com/open-api-spex/open_api_spex)
[![Hex.pm](https://img.shields.io/hexpm/v/open_api_spex.svg)](https://hex.pm/packages/open_api_spex)


Leverage Open API Specification 3 (formerly Swagger) to document, test, validate and explore your Plug and Phoenix APIs.

 - Generate and serve a JSON Open API Spec document from your code
 - Use the spec to cast request params to well defined schema structs
 - Validate params against schemas, eliminate bad requests before they hit your controllers
 - Validate responses against schemas in tests, ensuring your docs are accurate and reliable
 - Explore the API interactively with with [SwaggerUI](https://swagger.io/swagger-ui/)

Full documentation available on [hexdocs](https://hexdocs.pm/open_api_spex/)

## Installation

The package can be installed by adding `open_api_spex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:open_api_spex, "~> 3.5"}
  ]
end
```

## Generate Spec

Start by adding an `ApiSpec` module to your application to populate an `OpenApiSpex.OpenApi` struct.

```elixir
defmodule MyAppWeb.ApiSpec do
  alias OpenApiSpex.{OpenApi, Server, Info, Paths}
  alias MyAppWeb.{Endpoint, Router}
  @behaviour OpenApi

  @impl OpenApi
  def spec do
    %OpenApi{
      servers: [
        # Populate the Server info from a phoenix endpoint
        Server.from_endpoint(Endpoint)
      ],
      info: %Info{
        title: "My App",
        version: "1.0"
      },
      # populate the paths from a phoenix router
      paths: Paths.from_router(Router)
    }
    |> OpenApiSpex.resolve_schema_modules() # discover request/response schemas from path specs
  end
end
```

For each plug (controller) that will handle api requests, add an `open_api_operation` callback.
It will be passed the plug opts that were declared in the router, this will be the action for a phoenix controller. The callback populates an `OpenApiSpex.Operation` struct describing the plug/action.

```elixir
defmodule MyAppWeb.UserController do
  alias OpenApiSpex.Operation
  alias MyAppWeb.Schemas.UserResponse

  @spec open_api_operation(atom) :: Operation.t()
  def open_api_operation(action) do
    operation = String.to_existing_atom("#{action}_operation")
    apply(__MODULE__, operation, [])
  end

  @spec show_operation() :: Operation.t()
  def show_operation() do
    %Operation{
      tags: ["users"],
      summary: "Show user",
      description: "Show a user by ID",
      operationId: "UserController.show",
      parameters: [
        Operation.parameter(:id, :path, :integer, "User ID", example: 123, required: true)
      ],
      responses: %{
        200 => Operation.response("User", "application/json", UserResponse)
      }
    }
  end

  # Controller's `show` action
  def show(conn, %{id: id}) do
    {:ok, user} = MyApp.Users.find_by_id(id)
    json(conn, 200, user)
  end

end
```

Alternatively, you can create an operation file separately using `defdelegate`.

```elixir
# Phoenix's controller
defmodule MyAppWeb.UserController do
  defdelegate open_api_operation(action), to: MyAppWeb.UserApiOperation

  def show(conn, %{id: id}) do
    {:ok, user} = MyApp.Users.find_by_id(id)
    json(conn, 200, user)
  end
end

# Open API Spex operations
defmodule MyAppWeb.UserApiOperation do
  alias OpenApiSpex.Operation
  alias MyAppWeb.Schemas.UserResponse

  @spec open_api_operation(atom) :: Operation.t()
  def open_api_operation(action) do
    operation = String.to_existing_atom("#{action}_operation")
    apply(__MODULE__, operation, [])
  end

  @spec show_operation() :: Operation.t()
  def show_operation() do
    %Operation{
      tags: ["users"],
      summary: "Show user",
      description: "Show a user by ID",
      operationId: "UserController.show",
      parameters: [
        Operation.parameter(:id, :path, :integer, "User ID", example: 123, required: true)
      ],
      responses: %{
        200 => Operation.response("User", "application/json", UserResponse)
      }
    }
  end
end
```

For examples of other action operations, see the
[example web app](https://github.com/open-api-spex/open_api_spex/blob/master/examples/phoenix_app/lib/phoenix_app_web/controllers/user_controller.ex).

Next, declare JSON schema modules for the request and response bodies.
In each schema module, call `OpenApiSpex.schema/1`, passing the schema definition. The schema must
have keys described in `OpenApiSpex.Schema.t`. This will define a `%OpenApiSpex.Schema{}` struct.
This struct is made available from the `schema/0` public function, which is generated by `OpenApiSpex.schema/1`.

You may optionally have the data described by the schema turned into a struct linked to the JSON schema by adding `"x-struct": __MODULE__`
to the schema.

```elixir
defmodule MyAppWeb.Schemas do
  alias OpenApiSpex.Schema

  defmodule User do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "User",
      description: "A user of the app",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "User ID"},
        name: %Schema{type: :string, description: "User name", pattern: ~r/[a-zA-Z][a-zA-Z0-9_]+/},
        email: %Schema{type: :string, description: "Email address", format: :email},
        birthday: %Schema{type: :string, description: "Birth date", format: :date},
        inserted_at: %Schema{
          type: :string,
          description: "Creation timestamp",
          format: :"date-time"
        },
        updated_at: %Schema{type: :string, description: "Update timestamp", format: :"date-time"}
      },
      required: [:name, :email],
      example: %{
        "id" => 123,
        "name" => "Joe User",
        "email" => "joe@gmail.com",
        "birthday" => "1970-01-01T12:34:55Z",
        "inserted_at" => "2017-09-12T12:34:55Z",
        "updated_at" => "2017-09-13T10:11:12Z"
      }
    })
  end

  defmodule UserResponse do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "UserResponse",
      description: "Response schema for single user",
      type: :object,
      properties: %{
        data: User
      },
      example: %{
        "data" => %{
          "id" => 123,
          "name" => "Joe User",
          "email" => "joe@gmail.com",
          "birthday" => "1970-01-01T12:34:55Z",
          "inserted_at" => "2017-09-12T12:34:55Z",
          "updated_at" => "2017-09-13T10:11:12Z"
        }
      }
    })
  end
end
```

For more examples of schema definitions, see the
[sample Phoenix app](https://github.com/open-api-spex/open_api_spex/blob/master/examples/phoenix_app/lib/phoenix_app_web/schemas.ex)

## Serve the Spec

To serve the API spec from your application, first add the `OpenApiSpex.Plug.PutApiSpec` plug somewhere in the pipeline.

```elixir
  pipeline :api do
    plug OpenApiSpex.Plug.PutApiSpec, module: MyAppWeb.ApiSpec
  end
```

Now the spec will be available for use in downstream plugs.
The `OpenApiSpex.Plug.RenderSpec` plug will render the spec as JSON:

```elixir
  scope "/api" do
    pipe_through :api
    resources "/users", MyAppWeb.UserController, only: [:create, :index, :show]
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end
```

## Generating the Spec

Optionally, you can create a mix task to write the swagger file to disk:

```elixir
defmodule Mix.Tasks.MyApp.OpenApiSpec do
  def run([output_file]) do
    MyAppWeb.Endpoint.start_link() # Required if using for OpenApiSpex.Server.from_endpoint/1

    json =
      MyAppWeb.ApiSpec.spec()
      |> Jason.encode!(pretty: true)

    :ok = File.write!(output_file, json)
  end
end
```

Generate the file with: `mix my_app.openapispec spec.json`

## Serve Swagger UI

Once your API spec is available through a route (see "Serve the Spec"), the `OpenApiSpex.Plug.SwaggerUI` plug can be used to
serve a SwaggerUI interface.  The `path:` plug option must be supplied to give the path to the API spec.

All JavaScript and CSS assets are sourced from cdnjs.cloudflare.com, rather than vendoring into this package.

```elixir
  scope "/" do
    pipe_through :browser # Use the default browser stack

    get "/", MyAppWeb.PageController, :index
    get "/swaggerui", OpenApiSpex.Plug.SwaggerUI, path: "/api/openapi"
  end

  scope "/api" do
    pipe_through :api

    resources "/users", MyAppWeb.UserController, only: [:create, :index, :show]
    get "/openapi", OpenApiSpex.Plug.RenderSpec, []
  end
```

## Importing an existing schema file

> :warning: This functionality currently converts Strings into Atoms, which makes it potentially [vulnerable to DoS attacks](https://til.hashrocket.com/posts/gkwwfy9xvw-converting-strings-to-atoms-safely). We recommend that you load Open API Schemas from *known files* during application startup and *not dynamically from external sources at runtime*.

OpenApiSpex has functionality to import an existing schema, casting it into an %OpenApi{} struct. This means you can load a schema that is JSON or YAML encoded. See the example below:

```elixir
# Importing an existing JSON encoded schema
open_api_spec_from_json = "encoded_schema.json"
  |> File.read!()
  |> Jason.decode!()
  |> OpenApiSpex.OpenApi.Decode.decode()

# Importing an existing YAML encoded schema
open_api_spec_from_yaml = "encoded_schema.yaml"
  |> YamlElixir.read_all_from_file!()
  |> OpenApiSpex.OpenApi.Decode.decode()
```

You can then use the loaded spec to with `OpenApiSpex.cast_and_validate/4`, like:

```elixir
{:ok, _} = OpenApiSpex.cast_and_validate(
  open_api_spec_from_json, # or open_api_spec_from_yaml
  spec.paths["/some_path"].post,
  test_conn,
  "application/json"
)
```

## Validating and Casting Params

OpenApiSpex can automatically validate requests before they reach the controller action function. Or if you prefer,
you can explicitly call on OpenApiSpex to cast and validate the params within the controller action. This section
describes the former.

First, the `plug OpenApiSpex.Plug.PutApiSpec` needs to be called in the Router, as described above.

Add the `OpenApiSpex.Plug.CastAndValidate` plug to a controller to validate request parameters and to cast to Elixir types defined by the operation schema.

```elixir
# Phoenix
plug OpenApiSpex.Plug.CastAndValidate
# Plug
plug OpenApiSpex.Plug.CastAndValidate, operation_id: "UserController.create
```

For Phoenix apps, the `operation_id` can be inferred from the contents of `conn.private`.

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  alias OpenApiSpex.Operation
  alias MyAppWeb.Schemas.{User, UserRequest, UserResponse}

  plug OpenApiSpex.Plug.CastAndValidate

  def open_api_operation(action) do
    apply(__MODULE__, :"#{action}_operation", [])
  end

  def create_operation do
    import Operation
    %Operation{
      tags: ["users"],
      summary: "Create user",
      description: "Create a user",
      operationId: "UserController.create",
      parameters: [
        parameter(:id, :query, :integer, "user ID")
      ],
      requestBody: request_body("The user attributes", "application/json", UserRequest),
      responses: %{
        201 => response("User", "application/json", UserResponse)
      }
    }
  end

  def create(conn = %{body_params: %UserRequest{user: %User{name: name, email: email, birthday: birthday = %Date{}}}}, %{id: id}) do
    # conn.body_params cast to UserRequest struct
    # conn.params.id cast to integer
  end
end
```

Now the client will receive a 422 response whenever the request fails to meet the validation rules from the api spec.

The response body will include the validation error message:

```json
{
  "errors": [
    {
      "message": "Invalid format. Expected :date",
      "source": {
        "pointer": "/data/birthday"
      },
      "title": "Invalid value"
    }
  ]
}
```

See also `OpenApiSpex.cast_value/3` for casting and validating outside of a `plug` pipeline.

## Validate Examples

As schemas evolve, you may want to confirm that the examples given match the schemas.
Use the `OpenApiSpex.TestAssertions` module to assert on schema validations.

```elixir
use ExUnit.Case
import OpenApiSpex.TestAssertions

test "UsersResponse example matches schema" do
  api_spec = MyAppWeb.ApiSpec.spec()
  schema = MyAppWeb.Schemas.UsersResponse.schema()
  assert_schema(schema.example, "UsersResponse", api_spec)
end
```

## Validate Responses

API responses can be tested against schemas using `OpenApiSpex.TestAssertions` also:

```elixir
use MyAppWeb.ConnCase
import OpenApiSpex.TestAssertions

test "UserController produces a UsersResponse", %{conn: conn} do
  api_spec = MyAppWeb.ApiSpec.spec()
  json =
    conn
    |> get(user_path(conn, :index))
    |> json_response(200)

  assert_schema(json, "UsersResponse", api_spec)
end
```

## Experimental ExDoc-Based API Specifications

Starting with version 3.5.0, a new, experimental API is available to specify endpoints from the controller,
using ExDoc tags. See the example below.

Because this feature is experimental, it is likely to change in the future, until it becomes stable. Use
at your own risk.

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use OpenApiSpex.Controller

  @doc """
  List users
  """
  @doc responses: %{
    200 => {"Users", "application/json", MyAppWeb.Schema.Users}
  }
  def index(conn, _params) do
    {:ok, users} = MyApp.Users.all()

    json(conn, users)
  end

  @doc """
  Update user
  """
  @doc parameters: [
    id: [in: :query, type: :string, required: true, description: "User ID"]
  ]
  @doc responses: %{
    200 => {"User", "application/json", MyAppWeb.Schema.User}
  }
  def update(conn, %{id: id}) do
    with {:ok, user} <- MyApp.Users.update(conn.body_params) do
      json(conn, user)
    end
  end
end
```
