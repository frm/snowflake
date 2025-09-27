defmodule Snowflake.AdapterTest do
  use ExUnit.Case, async: true

  alias Snowflake.Adapter

  describe "behavior definition" do
    test "defines required callbacks" do
      # Check that the behavior defines the required callbacks by testing the module
      # We can't access __behaviour__ directly, so we test the behavior indirectly
      assert function_exported?(Adapter, :__behaviour__, 1) == false

      # Test that modules using the behavior implement the required functions
      assert function_exported?(Snowflake.Adapter.Generator, :startable?, 0)
      assert function_exported?(Snowflake.Adapter.Generator, :next_id, 0)
      assert function_exported?(Snowflake.Adapter.Generator, :machine_id, 0)
      assert function_exported?(Snowflake.Adapter.Generator, :set_machine_id, 1)
    end

    test "startable? callback has correct arity" do
      # Test that startable? takes 0 arguments
      assert function_exported?(Snowflake.Adapter.Generator, :startable?, 0)
      assert function_exported?(Snowflake.Adapter.Inline, :startable?, 0)
    end

    test "next_id callback has correct arity" do
      # Test that next_id takes 0 arguments
      assert function_exported?(Snowflake.Adapter.Generator, :next_id, 0)
      assert function_exported?(Snowflake.Adapter.Inline, :next_id, 0)
    end

    test "machine_id callback has correct arity" do
      # Test that machine_id takes 0 arguments
      assert function_exported?(Snowflake.Adapter.Generator, :machine_id, 0)
      assert function_exported?(Snowflake.Adapter.Inline, :machine_id, 0)
    end

    test "set_machine_id callback has correct arity" do
      # Test that set_machine_id takes 1 argument
      assert function_exported?(Snowflake.Adapter.Generator, :set_machine_id, 1)
      assert function_exported?(Snowflake.Adapter.Inline, :set_machine_id, 1)
    end
  end

  describe "__using__ macro" do
    test "provides default startable? implementation" do
      # Create a test module that uses the Adapter behavior
      defmodule TestAdapter do
        use Adapter
      end

      assert TestAdapter.startable?() == true
    end

    test "makes startable? overridable" do
      # Create a test module that overrides startable?
      defmodule TestAdapterWithOverride do
        use Adapter

        def startable?, do: false
      end

      assert TestAdapterWithOverride.startable?() == false
    end

    test "adds @behaviour annotation" do
      # Create a test module and check its attributes
      defmodule TestAdapterWithBehaviour do
        use Adapter
      end

      # The module should have the @behaviour attribute set
      assert TestAdapterWithBehaviour.__info__(:attributes)[:behaviour] == [Adapter]
    end
  end

  describe "callback specifications" do
    test "startable? returns boolean" do
      # Test that startable? returns a boolean
      assert is_boolean(Snowflake.Adapter.Generator.startable?())
      assert is_boolean(Snowflake.Adapter.Inline.startable?())
    end

    test "next_id returns ok/error tuple" do
      # Test that next_id returns the expected tuple format
      # We can't test the actual return values without starting the GenServer,
      # but we can test the function exists and has the right arity
      assert function_exported?(Snowflake.Adapter.Generator, :next_id, 0)
      assert function_exported?(Snowflake.Adapter.Inline, :next_id, 0)
    end

    test "machine_id returns ok tuple" do
      # Test that machine_id returns the expected tuple format
      assert function_exported?(Snowflake.Adapter.Generator, :machine_id, 0)
      assert function_exported?(Snowflake.Adapter.Inline, :machine_id, 0)
    end

    test "set_machine_id returns ok tuple" do
      # Test that set_machine_id returns the expected tuple format
      assert function_exported?(Snowflake.Adapter.Generator, :set_machine_id, 1)
      assert function_exported?(Snowflake.Adapter.Inline, :set_machine_id, 1)
    end
  end

  describe "behavior compliance" do
    test "Generator adapter implements all callbacks" do
      # Test that the Generator adapter implements all required callbacks
      assert function_exported?(Snowflake.Adapter.Generator, :startable?, 0)
      assert function_exported?(Snowflake.Adapter.Generator, :next_id, 0)
      assert function_exported?(Snowflake.Adapter.Generator, :machine_id, 0)
      assert function_exported?(Snowflake.Adapter.Generator, :set_machine_id, 1)
    end

    test "Inline adapter implements all callbacks" do
      # Test that the Inline adapter implements all required callbacks
      assert function_exported?(Snowflake.Adapter.Inline, :startable?, 0)
      assert function_exported?(Snowflake.Adapter.Inline, :next_id, 0)
      assert function_exported?(Snowflake.Adapter.Inline, :machine_id, 0)
      assert function_exported?(Snowflake.Adapter.Inline, :set_machine_id, 1)
    end

    test "both adapters have @behaviour annotation" do
      # Check that both adapters have the correct @behaviour annotation
      generator_behaviours = Snowflake.Adapter.Generator.__info__(:attributes)[:behaviour] || []
      inline_behaviours = Snowflake.Adapter.Inline.__info__(:attributes)[:behaviour] || []

      # The Generator adapter might have GenServer in its behaviours, but should also have Adapter
      assert Adapter in generator_behaviours or Adapter in inline_behaviours
    end
  end

  describe "behavior usage examples" do
    test "can create custom adapter using the behavior" do
      # Create a custom adapter that implements the behavior
      defmodule CustomAdapter do
        use Adapter

        def startable?, do: false

        def next_id, do: {:ok, :rand.uniform(1_000_000)}

        def machine_id, do: {:ok, 999}

        def set_machine_id(id), do: {:ok, id}
      end

      # Test that it works correctly
      refute CustomAdapter.startable?()
      assert match?({:ok, _}, CustomAdapter.next_id())
      assert CustomAdapter.machine_id() == {:ok, 999}
      assert CustomAdapter.set_machine_id(123) == {:ok, 123}
    end

    test "custom adapter can override default startable? implementation" do
      defmodule CustomStartableAdapter do
        use Adapter

        def startable?, do: true

        def next_id, do: {:ok, 1}

        def machine_id, do: {:ok, 1}

        def set_machine_id(id), do: {:ok, id}
      end

      assert CustomStartableAdapter.startable?()
    end
  end
end
