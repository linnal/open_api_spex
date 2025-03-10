# 3.5.0

Thanks to the contributions of the community ❤️💙💛💜🧡

* [surik](https://github.com/surik)
* [fmcgeough](https://github.com/fmcgeough)
* [zero778](https://github.com/zero778)
* [vovayartsev](https://github.com/vovayartsev)
* [superhawk610](https://github.com/superhawk610)
* [jung-hunsoo](https://github.com/jung-hunsoo)
* [supermaciz](https://github.com/supermaciz)
* [Geekfish](https://github.com/Geekfish)
* [mrmstn](https://github.com/mrmstn)
* [waltfy](https://github.com/waltfy)
* [ggpasqualino](https://github.com/ggpasqualino)
* [hauleth](https://github.com/hauleth)

- Feature: Ability to import Open API documents instead of defining them in Elixir (#152)
- Feature: Add `display_operation_id` option to SwaggerUI (#138)
- Feature: Schema validation: schema type required when `properties` is present (#146)
- Feature: Improve reporting of test assertion failures (#150)
- Feature: Support for `min_properties` validation for Object properties (#131)
- Feature: Support property defaults in new Cast & Validate API (#145)
- Feature: Support for casting file uploads (#133)
- Feature: Support "$ref" in operation's parameters (#137)
- Feature: Experimental ExDoc-based endpoint API specifications (#162)
- Deprecation: Deprecate old cast and validation API (#153)
- Deprecation: Set minimum supported Elixir version to 1.7, maximum 1.9 (#130)
- Fix: Prevent example properties with nil values from being stripped out during JSON encoding (#142)
- Fix: casting/validating of oneOf, anyOf (#148)
- Fix: Pass additional properties through when allowed via `additionalProperties` (#155)
- Fix: for `allOf` definitions for multi-typed `allOf` array and complex structs with inheritance (#156)
- Fix: Allow a root-level property of compiled schema to be a schema (#158)
- Docs: Fix bugs and improve wording in README (#126)
- Docs: update phoenix guide and samples (#129)
- Docs: README instructions for separating API operation from controller (#140)

The original cast & validation API has been deprecated and replaced with an API that was introduced in 3.2.0.
Using the old API will now result in compiler and runtime warnings.

Old API:
```elixir
defmodule PhoenixAppWeb.UserController do
  use PhoenixAppWeb, :controller
  plug OpenApiSpex.Plug.Cast
  plug OpenApiSpex.Plug.Validate
end
```

Will result in:
```
warning: OpenApiSpex.Plug.Cast.call/2 is deprecated. Use OpenApiSpex.Plug.CastAndValidate instead
  test/support/user_controller.ex:1

warning: OpenApiSpex.Plug.Validate.call/2 is deprecated. Use OpenApiSpex.Plug.CastAndValidate.call/2 instead
  test/support/user_controller.ex:1
```

New API
```elixir
defmodule PhoenixAppWeb.UserController do
  use PhoenixAppWeb, :controller
  plug OpenApiSpex.Plug.CastAndValidate
end
```

Note that this changes the default error response. Before, it was a single, plain-text error message.
Now, it's a list of error maps, containing more error information.

Old API:
```elixir
defmodule MyAppWeb.MyControllerTest do
  use MyApp.ConnCase
  # Old module
  import OpenApiSpex.Test.Assertions

  ## The test themselves don't need to change

  test "UserController produces a UsersResponse", %{conn: conn} do
    api_spec = MyApp.ApiSpec.spec()
    json =
      conn
      |> get(user_path(conn, :index))
      |> json_response(200)

    assert_schema(json, "UsersResponse", api_spec)
  end

  test "something" do
    api_spec = MyApp.ApiSpec.spec()
    schema = MyApp.Schemas.UsersResponse.schema()
    assert_schema(schema.example, "UsersResponse", api_spec)
  end
end
```

Will produce:
```
warning: OpenApiSpex.Test.Assertions.assert_schema/3 is deprecated. Use OpenApiSpex.TestAssertions.assert_schema/3 instead
  test/my_controller_test.exs:21
```

New API:
```elixir
defmodule MyAppWeb.MyControllerTest do
  use MyApp.ConnCase
  # New module
  import OpenApiSpex.TestAssertions

  # The test themselves don't need to change,
  # but the new assertion is more discerning,
  # so it may find problems that the old API didn't.
end
```

# 3.4.0

Thanks to the contributions of the community ❤️💙💛💜🧡

 * [surik](https://github.com/surik)
 * [holsee](https://github.com/holsee)
 * [fmcgeough](https://github.com/fmcgeough)


 - Feature: the `OpenApiSpex` and `OpenApiSpex.Info` structs now support [extensions](https://swagger.io/docs/specification/openapi-extensions/) (#108) (#114)

 The `extensions` key may contain any additional data that should be included in the info, eg the `x-logo` and `x-tagGroups` extensions:

 ```elixir
  spec = %OpenApi{
    info: %Info{
      title: "Test",
      version: "1.0.0",
      extensions: %{
        "x-logo" => %{
          "url" => "https://example.com/logo.png",
          "backgroundColor" => "#FFFFFF",
          "altText" => "Example logo"
        }
      }
    },
    extensions: %{
      "x-tagGroups" => [
        %{
          "name" => "Methods",
          "tags" => [
            "Search",
            "Fetch",
            "Delete"
          ]
        }
      ]
    },
    paths: %{ ... }
  }
 ```

 - Deprecation: `OpenApiSpex.Server.from_endpoint/2` has been deprecated in favor of `OpenApiSpex.Server.from_endpoint/1`.
   Simply remove the `otp_app:` option from the call to use the new function. (#116)

```elixir
  # server = Server.from_endpoint(Endpoint, otp_app: :my_phoenix_app)
  server = Server.from_endpoint(MyPhoenixAppWeb.Endpoint)
```

 - Fix: The internal representation of a Phoenix Route struct changed in Phoenix 1.4.7 breaking the `OpenApiSpex.Paths.from_router/1` function. OpenApiSpex 3.4.0 will support both representations until the Phoenix API becomes stable. (#118)

# 3.3.0

Thanks to the contributions from the community! 👍

 * [hauleth](https://github.com/hauleth)
 * [cstaud](https://github.com/cstaud)
 * [xadhoom](https://github.com/xadhoom)
 * [nurugger07](https://github.com/nurugger07)
 * [fenollp](https://github.com/fenollp)
 * [moxley](https://github.com/moxley)

 - Feature: Enums expressed as atoms or atom-keyed maps can be cast from strings (or string-keyed maps). (#60) (#101)

Example:

```elixir
  parameters: [
    Operation.parameter(:sort, :query, :string, "sort direction", enum: [:asc, :desc])
  ],
```

 - Fix: Schema module references are resolved in in-line parameter/response schemas. (#77) (#105)

Example: The response schema is given in-line as an array, but items are resolved from the `User` module.

```elixir
  responses: %{
    200 => Operation.response(
      "User array",
      "application/json",
      %Schema{
        type: :array,
        items: MyApp.Schemas.User
      }
    )
  }
```

 - Fix: Ensure integer query parameters are validated correctly after conversion from string. (#106)
 - Fix: Ensure integers are validated correctly against schema `minimum`, `maximum`, `exlcusiveMinimum` and `exclusiveMaximum` attributes. (#97)
 - Fix: Ensure strings are cast to `Date` or `DateTime` types when the schema format is `:date` or `:date-time`. (#90) (#94)
 - Docs: The contract for module supplied to the `PutApiSpec` plug is now documented by the `OpenApi` behaviour. (#73) (#103)
 - Docs: Poison replaced with Jason in example and tests (#104)
 - Docs: Improved documentation for combined `CastAndValidate` plug. (#91)
 - Internals: Cache mapping from phoenix controller/action to OpenApi operation. (#102)


# 3.2.1

Patch release for documentation updates and improved error rendering Plug when using `CastAndValidate`.

Thanks [moxley](https://github.com/moxley)!

 - Cast and validate guide (#89)

# 3.2.0

This release contains many improvements and internal changes thanks to the contributions of the community!

* [moxley](https://github.com/moxley)
* [kpanic](https://github.com/kpanic)
* [hauleth](https://github.com/hauleth)
* [nurugger07](https://github.com/nurugger07)
* [ggpasqualino](https://github.com/ggpasqualino)
* [teamon](https://github.com/teamon)
* [bryannaegele](https://github.com/bryannaegele)

 - Feature: Send Plug CSRF token in x-csrf-token header from Swagger UI (#82)
 - Feature: Support `Jason` library for JSON serialization (#75)
 - Feature: Combine casting and validation into a single `CastAndValidate` Plug (#69) (#86)
 - Feature: Improved performance by avoiding copying of API Spec data in each request (#83)
 - Fix: Convert `integers` to `float` when casting to `number` type (#81) (#84)
 - Fix: Validate strings without trimming whitespace first (#79)
 - Fix: Exclusive Minimum and Exclusive maximum are validated correctly (#68)
 - Fix: Report errors when unable to convert to the expected number/string/boolean type (#64)
 - Fix: Gracefully report error when failing to convert request params to an object type (#63)
 - Internals: Improved code organisation of unit test suite (#62)

# 3.1.0

 - Add support for validating polymorphic schemas using `oneOf`, `anyOf`, `allOf`, `not` constructs.
 - Updated example apps to work with new API
 - CI has moved from travis-ci.org to travis-ci.com and now uses github apps integration.

 Thanks to [fenollp](https://github.com/fenollp) and [tapickell](https://github.com/tapickell) for contributions!

# 3.0.0

Major version bump as the behaviour of `OpenApiSpex.Plug.Cast` has changed (#39).
To enable requests that contain a body as well as path or query params, the result of casting the
request body is now placed in the `Conn.body_params` field, instead of the combined `Conn.params` field.

This requires changing code such as Phoenix controller actions to from

```elixir
def create(conn, %UserRequest{user: %User{name: name, email: email}}) do
```

to

```elixir
  def create(conn = %{body_params: %UserRequest{user: %User{name: name, email: email}}}, params) do
```

- Feature: A custom plug may be provided to render errors (#46)
- Fix compiler warnings and improve CI process (#53)
- Fix: Support casting GET requests without Content-Type header (#50, #49)
- Open API Spex has been moved to the new `open-api-spex` Github organisation

# 2.3.1

- Docs: Update example application to include swagger generate mix task (#41)
- Fix: Ignore charset in content-type header when looking up schema by content type. (#45)

Thanks to [dmt](https://github.com/dmt) and [fenollp](https://github.com/fenollp) for contributions!

# 2.3.0

- Feature: Validate string enum types. (#33)
- Feature: Detect and report missing API spec in `OpenApiSpex.Plug.Cast` (#37)
- Fix: Correct atom for parameter `style` field typespec (#36)

Thanks to [slavo2](https://github.com/slavo2) and [anagromataf](https://github.com/anagromataf) for
contributions!

# 2.2.0

- Feature: Support composite schemas in `OpenApiSpex.schema`

structs defined with `OpenApiSpex.schema` will include all properties defined in schemas
listed in `allOf`. See the `OpenApiSpex.Schema` docs for some examples.

- Feature: Support composite and polymorphic schemas with `OpenApiSpex.cast/3`.
   -  `discriminator` is used to cast polymorphic shemas to a more specific schema.
   -  `allOf` will cast all properties in each included schema
   -  `oneOf` / `anyOf` will attempt to use each schema until a successful cast is made

# 2.1.1

- Fix: (#24, #25) Operations that define `parameters` and a `requestBody` schema can be validated.

# 2.1.0

- Feature: (#16) Error response from `OpenApiSpex.cast` when value contains unknown properties and schema declares `additionalProperties: false`.
- Feature: (#20) Update swagger-ui to version 3.17.0.
- Fix: (#17, #21, #22) Update typespecs for struct types.

# 2.0.0

Major version update following from API change in `OpenApiSpex.cast` and `OpenApiSpex.validate`.
When casting/validating all parameters against an `OpenApiSpex.Operation`, the complete `Plug.Conn` struct must now be passed, where the combined params map was previously accepted.
This allows `OpenApiSpex.cast` / `OpenApiSpex.validate` to check that the parameters are being supplied in the expected location (query, path, body, header, cookie).
In version 2.0.0, only unexpected query parameters will cause a 422 response from `OpenApiSpex.Plug.Cast`, this may be extended in future versions to detect more invalid requests.

Thanks [cstaud](https://github.com/cstaud), [rutho](https://github.com/ThomasRueckert), [anagromataf](https://github.com/anagromataf) for contributions!


 - Change: (#9) swagger-ui updated to 3.13.4
 - Change (#9) Unexpected query parameters will produce an error response from `OpenApiSpex.Plug.Cast`
 - Change: (#9) `OpenApiSpex.cast/4` now requires a complete `Plug.Conn` struct when casting all parameters of an `OpenApiSpex.Operation`
 - Change: (#14) `OpenApiSpex.validate/4` now requires a complete `Plug.Conn` struct when validating all parameters of an `OpenApiSpex.Operation`
 - Fix: (#11) Support resolving list of schema modules in `oneOf`, `anyOf`, etc.
 - Fix: `OpenApiSpex.schema` macro allows defining schemas without any properties
 - Fix: type declarations better reflect when `nil` is allowed


# 1.1.4

 - `additionalProperties` is now `nil` by default, was previously `true`

# 1.1.3

 - Fix several bugs and make some minor enhancements to schema casting and validating.
 - Add sample application to enable end-to-end testing

# 1.1.2

Fix openapi version output in generated spec.

# 1.1.1

Update swagger-ui to version 3.3.2

# 1.1.0

Include path to invalid element in validation errors.
Eg: "#/user/name: Value does not match pattern: [a-zA-Z][a-zA-Z0-9_]+"

# 1.0.1

Cache API spec in application environment after first call to PutApiSpec plug

# 1.0.0

Initial release. This package is inspired by [phoenix_swagger](https://github.com/xerions/phoenix_swagger) but targets Open API Spec 3.0.


