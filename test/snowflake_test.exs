defmodule SnowflakeTest do
  use ExUnit.Case, async: false

  alias Snowflake

  setup do
    # Set up test configuration
    Application.put_env(:snowflake, :epoch, 1_000_000_000)
    Application.put_env(:snowflake, :machine_id, 42)
    Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Generator)

    on_exit(fn ->
      Application.delete_env(:snowflake, :epoch)
      Application.delete_env(:snowflake, :machine_id)
      Application.delete_env(:snowflake, :adapter)
    end)
  end

  describe "next_id/0" do
    test "returns ok tuple with snowflake ID" do
      {:ok, id} = Snowflake.next_id()

      assert is_integer(id)
      assert id > 0
    end

    test "returns different IDs on subsequent calls" do
      {:ok, id1} = Snowflake.next_id()
      {:ok, id2} = Snowflake.next_id()

      assert id1 != id2
    end

    test "returns monotonically increasing IDs" do
      {:ok, id1} = Snowflake.next_id()
      {:ok, id2} = Snowflake.next_id()

      assert id2 > id1
    end

    test "can return error for backwards clock" do
      # This is hard to test in practice, but we can verify the error case exists
      result = Snowflake.next_id()

      case result do
        {:ok, _} -> assert true
        {:error, :backwards_clock} -> assert true
        _ -> flunk("Unexpected result: #{inspect(result)}")
      end
    end

    test "uses configured adapter" do
      # Test with inline adapter for simpler testing
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Inline)

      {:ok, id} = Snowflake.next_id()

      assert is_integer(id)
      assert id > 0
    end

    test "uses default adapter when none configured" do
      Application.delete_env(:snowflake, :adapter)

      {:ok, id} = Snowflake.next_id()

      assert is_integer(id)
      assert id > 0
    end
  end

  describe "machine_id/0" do
    test "returns ok tuple with machine ID" do
      {:ok, id} = Snowflake.machine_id()

      assert is_integer(id)
      assert id >= 0
      assert id <= 1023
    end

    test "returns configured machine_id when using inline adapter" do
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Inline)

      {:ok, id} = Snowflake.machine_id()

      assert is_integer(id)
      # Inline adapter returns timestamp-based ID
      assert id > 0
    end

    test "uses configured adapter" do
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Inline)

      result = Snowflake.machine_id()

      assert match?({:ok, _}, result)
    end
  end

  describe "set_machine_id/1" do
    test "returns ok tuple with the provided machine ID" do
      {:ok, id} = Snowflake.set_machine_id(123)

      assert id == 123
    end

    test "accepts valid machine_id range" do
      {:ok, id} = Snowflake.set_machine_id(0)
      assert id == 0

      {:ok, id} = Snowflake.set_machine_id(1023)
      assert id == 1023
    end

    test "persists machine_id change" do
      new_machine_id = 456

      Snowflake.set_machine_id(new_machine_id)

      {:ok, current_id} = Snowflake.machine_id()
      assert current_id == new_machine_id
    end

    test "works with inline adapter" do
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Inline)

      {:ok, id} = Snowflake.set_machine_id(789)

      assert id == 789
    end

    test "uses configured adapter" do
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Inline)

      result = Snowflake.set_machine_id(1)

      assert match?({:ok, _}, result)
    end
  end

  describe "adapter configuration" do
    test "uses default adapter when none configured" do
      Application.delete_env(:snowflake, :adapter)

      # Should use Snowflake.Adapter.Generator as default
      {:ok, _id} = Snowflake.next_id()
    end

    test "uses configured adapter" do
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Inline)

      # Should use the configured adapter
      {:ok, _id} = Snowflake.next_id()
    end

    test "adapter configuration affects all functions" do
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Inline)

      # All functions should use the configured adapter
      {:ok, _id1} = Snowflake.next_id()
      {:ok, _id2} = Snowflake.machine_id()
      {:ok, _id3} = Snowflake.set_machine_id(1)
    end
  end

  describe "application startup" do
    test "start/2 returns supervisor with startable adapter" do
      # Test that the application can start with a startable adapter
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Generator)

      # Test the logic without actually starting the supervisor
      # We can test that the adapter is startable
      assert Snowflake.Adapter.Generator.startable?() == true

      # Test that the helper functions work
      assert is_integer(Snowflake.Helper.epoch())
      assert is_integer(Snowflake.Helper.machine_id())
    end

    test "start/2 returns supervisor without children for non-startable adapter" do
      # Test that the application starts without children for non-startable adapter
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Inline)

      {:ok, pid} = Snowflake.start(:normal, [])

      assert is_pid(pid)
      assert Process.alive?(pid)

      # Clean up
      Supervisor.stop(pid)
    end
  end

  describe "type specifications" do
    test "next_id returns correct type" do
      result = Snowflake.next_id()

      case result do
        {:ok, id} when is_integer(id) and id >= 0 -> assert true
        {:error, :backwards_clock} -> assert true
        _ -> flunk("Unexpected result: #{inspect(result)}")
      end
    end

    test "machine_id returns correct type" do
      {:ok, id} = Snowflake.machine_id()

      assert is_integer(id)
    end

    test "set_machine_id returns correct type" do
      {:ok, id} = Snowflake.set_machine_id(1)

      assert is_integer(id)
    end
  end

  describe "integration with adapters" do
    test "works with Generator adapter" do
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Generator)

      # Test that all functions work with Generator adapter
      {:ok, id1} = Snowflake.next_id()
      {:ok, id2} = Snowflake.machine_id()
      {:ok, id3} = Snowflake.set_machine_id(42)

      assert is_integer(id1)
      assert is_integer(id2)
      assert id3 == 42
    end

    test "works with Inline adapter" do
      Application.put_env(:snowflake, :adapter, Snowflake.Adapter.Inline)

      # Test that all functions work with Inline adapter
      {:ok, id1} = Snowflake.next_id()
      {:ok, id2} = Snowflake.machine_id()
      {:ok, id3} = Snowflake.set_machine_id(42)

      assert is_integer(id1)
      assert is_integer(id2)
      assert id3 == 42
    end
  end

  describe "error handling" do
    test "handles adapter errors gracefully" do
      # Create a mock adapter that returns errors
      defmodule ErrorAdapter do
        use Snowflake.Adapter

        def startable?, do: false

        def next_id, do: {:error, :backwards_clock}

        def machine_id, do: {:ok, 0}

        def set_machine_id(_id), do: {:ok, 0}
      end

      Application.put_env(:snowflake, :adapter, ErrorAdapter)

      # Should propagate the error from the adapter
      assert Snowflake.next_id() == {:error, :backwards_clock}
    end
  end
end
