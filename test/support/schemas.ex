defmodule OpenApiSpexTest.Schemas do
  require OpenApiSpex
  alias OpenApiSpex.Reference
  alias OpenApiSpex.Schema

  defmodule Helper do
    def prepare_struct([%Reference{"$ref": "#/components/schemas/" <> name} | tail]) do
      schema =
        apply(String.to_existing_atom("Elixir.OpenApiSpexTest.Schemas." <> name), :schema, [])

      prepare_struct([schema | tail])
    end

    def prepare_struct([%Schema{properties: props} | tail]) when is_map(props) do
      keys = Map.keys(props)
      keys ++ prepare_struct(tail)
    end

    def prepare_struct([%Schema{allOf: allOf} | tail]) when is_list(allOf) do
      prepare_struct(allOf ++ tail)
    end

    def prepare_struct([module_name | tail]) when is_atom(module_name) do
      prepare_struct([module_name.schema() | tail])
    end

    def prepare_struct([]) do
      []
    end
  end

  defmodule Size do
    OpenApiSpex.schema(%{
      title: "Size",
      description: "A size of a pet",
      type: :object,
      properties: %{
        unit: %Schema{type: :string, description: "SI unit name", default: "cm"},
        value: %Schema{type: :integer, description: "Size in given unit", default: 100}
      },
      required: [:unit, :value]
    })
  end

  defmodule User do
    OpenApiSpex.schema(%{
      title: "User",
      description: "A user of the app",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "User ID"},
        name: %Schema{type: :string, description: "User name", pattern: ~r/[a-zA-Z][a-zA-Z0-9_]+/},
        email: %Schema{type: :string, description: "Email address", format: :email},
        inserted_at: %Schema{
          type: :string,
          description: "Creation timestamp",
          format: :"date-time"
        },
        updated_at: %Schema{type: :string, description: "Update timestamp", format: :"date-time"}
      },
      required: [:name, :email],
      additionalProperties: false,
      example: %{
        "id" => 123,
        "name" => "Joe User",
        "email" => "joe@gmail.com",
        "inserted_at" => "2017-09-12T12:34:55Z",
        "updated_at" => "2017-09-13T10:11:12Z"
      }
    })
  end

  defmodule ContactInfo do
    OpenApiSpex.schema(%{
      title: "ContactInfo",
      description: "A users contact information",
      type: :object,
      properties: %{
        phone_number: %Schema{type: :string, description: "Phone number"},
        postal_address: %Schema{type: :string, description: "Postal address"}
      },
      required: [:phone_number],
      additionalProperties: false,
      example: %{
        "phone_number" => "555-123-456",
        "postal_address" => "123 Evergreen Tce"
      }
    })
  end

  defmodule CreditCardPaymentDetails do
    OpenApiSpex.schema(%{
      title: "CreditCardPaymentDetails",
      description: "Payment details when using credit-card method",
      type: :object,
      properties: %{
        credit_card_number: %Schema{type: :string, description: "Credit card number"},
        name_on_card: %Schema{type: :string, description: "Name as appears on card"},
        expiry: %Schema{type: :string, description: "4 digit expiry MMYY"}
      },
      required: [:credit_card_number, :name_on_card, :expiry],
      example: %{
        "credit_card_number" => "1234-5678-1234-6789",
        "name_on_card" => "Joe User",
        "expiry" => "1234"
      }
    })
  end

  defmodule DirectDebitPaymentDetails do
    OpenApiSpex.schema(%{
      title: "DirectDebitPaymentDetails",
      description: "Payment details when using direct-debit method",
      type: :object,
      properties: %{
        account_number: %Schema{type: :string, description: "Bank account number"},
        account_name: %Schema{type: :string, description: "Name of account"},
        bsb: %Schema{type: :string, description: "Branch identifier"}
      },
      required: [:account_number, :account_name, :bsb],
      example: %{
        "account_number" => "12349876",
        "account_name" => "Joes Savings Account",
        "bsb" => "123-4567"
      }
    })
  end

  defmodule PaymentDetails do
    OpenApiSpex.schema(%{
      title: "PaymentDetails",
      description: "Abstract Payment details type",
      type: :object,
      oneOf: [
        CreditCardPaymentDetails,
        DirectDebitPaymentDetails
      ]
    })
  end

  defmodule UserRequest do
    OpenApiSpex.schema(%{
      title: "UserRequest",
      description: "POST body for creating a user",
      type: :object,
      properties: %{
        user: User
      },
      example: %{
        "user" => %{
          "name" => "Joe User",
          "email" => "joe@gmail.com"
        }
      }
    })
  end

  defmodule UserResponse do
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
          "inserted_at" => "2017-09-12T12:34:55Z",
          "updated_at" => "2017-09-13T10:11:12Z"
        }
      }
    })
  end

  defmodule UsersResponse do
    OpenApiSpex.schema(%{
      title: "UsersResponse",
      description: "Response schema for multiple users",
      type: :object,
      properties: %{
        data: %Schema{description: "The users details", type: :array, items: User}
      },
      example: %{
        "data" => [
          %{
            "id" => 123,
            "name" => "Joe User",
            "email" => "joe@gmail.com"
          },
          %{
            "id" => 456,
            "name" => "Jay Consumer",
            "email" => "jay@yahoo.com"
          }
        ]
      }
    })
  end

  defmodule EntityWithDict do
    OpenApiSpex.schema(%{
      title: "EntityWithDict",
      description: "Entity with a dictionary defined via additionalProperties",
      type: :object,
      properties: %{
        id: %Schema{type: :integer, description: "Entity ID"},
        stringDict: %Schema{
          type: :object,
          description: "String valued dict",
          additionalProperties: %Schema{type: :string}
        },
        anyTypeDict: %Schema{
          type: :object,
          description: "Untyped valued dict",
          additionalProperties: true
        }
      },
      example: %{
        "id" => 123,
        "stringDict" => %{"key1" => "value1", "key2" => "value2"},
        "anyTypeDict" => %{"key1" => 42, "key2" => %{"foo" => "bar"}}
      }
    })
  end

  defmodule PetType do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "PetType",
      type: :object,
      required: [:pet_type],
      properties: %{
        pet_type: %Schema{
          type: :string
        }
      }
    })
  end

  defmodule Cat do
    alias OpenApiSpex.Schema

    @behaviour OpenApiSpex.Schema
    @derive [Jason.Encoder]
    @schema %Schema{
      title: "Cat",
      type: :object,
      allOf: [
        PetType,
        %Schema{
          type: :object,
          properties: %{
            meow: %Schema{type: :string}
          },
          required: [:meow]
        }
      ],
      "x-struct": __MODULE__
    }

    def schema, do: @schema
    defstruct OpenApiSpexTest.Schemas.Helper.prepare_struct(@schema.allOf)
  end

  defmodule Dog do
    alias OpenApiSpex.Schema

    @behaviour OpenApiSpex.Schema
    @derive [Jason.Encoder]
    @schema %Schema{
      title: "Dog",
      type: :object,
      allOf: [
        PetType,
        %Schema{
          type: :object,
          properties: %{
            bark: %Schema{type: :string}
          },
          required: [:bark]
        }
      ],
      "x-struct": __MODULE__
    }

    def schema, do: @schema
    defstruct OpenApiSpexTest.Schemas.Helper.prepare_struct(@schema.allOf)
  end

  defmodule CatOrDog do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "CatOrDog",
      oneOf: [Cat, Dog]
    })
  end

  defmodule PrimitiveArray do
    require OpenApiSpex

    OpenApiSpex.schema(%{
      title: "PrimitiveArray",
      type: :array,
      items: %Schema{type: "string"},
      example: ["Foo"]
    })
  end

  defmodule PetResponse do
    OpenApiSpex.schema(%{
      title: "PetResponse",
      description: "Response schema for single pet",
      type: :object,
      properties: %{
        data: OpenApiSpexTest.Schemas.CatOrDog
      },
      example: %{
        "data" => %{
          "pet_type" => "Dog",
          "bark" => "woof"
        }
      }
    })
  end

  defmodule Pet do
    require OpenApiSpex
    alias OpenApiSpex.{Schema, Discriminator}

    OpenApiSpex.schema(%{
      title: "Pet",
      type: :object,
      oneOf: [Cat, Dog],
      discriminator: %Discriminator{
        propertyName: "pet_type"
      }
    })
  end

  defmodule PetsResponse do
    OpenApiSpex.schema(%{
      title: "PetsResponse",
      description: "Response schema for multiple pets",
      type: :object,
      properties: %{
        data: %Schema{
          description: "The pets details",
          type: :array,
          items: OpenApiSpexTest.Schemas.CatOrDog
        }
      },
      example: %{
        "data" => [
          %{
            "pet_type" => "Dog",
            "bark" => "woof"
          },
          %{
            "pet_type" => "Cat",
            "meow" => "meow"
          }
        ]
      }
    })
  end

  defmodule PetRequest do
    OpenApiSpex.schema(%{
      title: "PetRequest",
      description: "POST body for creating a pet",
      type: :object,
      properties: %{
        pet: CatOrDog
      },
      example: %{
        "pet" => %{
          "pet_type" => "Dog",
          "bark" => "woof"
        }
      }
    })
  end
end
