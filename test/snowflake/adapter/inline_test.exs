defmodule Snowflake.Adapter.InlineTest do
  use ExUnit.Case, async: true

  alias Snowflake.Adapter.Inline

  setup do
    # Set a test epoch for consistent testing
    Application.put_env(:snowflake, :epoch, 1_000_000_000)
    on_exit(fn -> Application.delete_env(:snowflake, :epoch) end)
  end

  describe "startable?/0" do
    test "returns false" do
      refute Inline.startable?()
    end
  end

  describe "next_id/0" do
    test "returns ok tuple with timestamp-based ID" do
      {:ok, id} = Inline.next_id()

      assert is_integer(id)
      assert id > 0
    end

    test "returns different IDs on subsequent calls" do
      {:ok, id1} = Inline.next_id()
      # Ensure different timestamps
      Process.sleep(1)
      {:ok, id2} = Inline.next_id()

      assert id1 != id2
    end

    test "returns monotonically increasing IDs" do
      {:ok, id1} = Inline.next_id()
      # Ensure different timestamps
      Process.sleep(1)
      {:ok, id2} = Inline.next_id()

      assert id2 > id1
    end

    test "uses nanosecond precision" do
      {:ok, id1} = Inline.next_id()
      # Sleep for 1ms
      Process.sleep(1)
      {:ok, id2} = Inline.next_id()

      # Even with 1ms sleep, nanosecond precision should show difference
      assert id2 > id1
    end
  end

  describe "machine_id/0" do
    test "returns ok tuple with timestamp-based ID" do
      {:ok, id} = Inline.machine_id()

      assert is_integer(id)
      assert id > 0
    end

    test "returns different IDs on subsequent calls" do
      {:ok, id1} = Inline.machine_id()
      # Ensure different timestamps
      Process.sleep(1)
      {:ok, id2} = Inline.machine_id()

      assert id1 != id2
    end

    test "returns monotonically increasing IDs" do
      {:ok, id1} = Inline.machine_id()
      # Ensure different timestamps
      Process.sleep(1)
      {:ok, id2} = Inline.machine_id()

      assert id2 > id1
    end
  end

  describe "set_machine_id/1" do
    test "returns ok tuple with the provided ID" do
      {:ok, id} = Inline.set_machine_id(42)

      assert id == 42
    end

    test "accepts any integer value" do
      {:ok, id} = Inline.set_machine_id(0)
      assert id == 0

      {:ok, id} = Inline.set_machine_id(1023)
      assert id == 1023

      {:ok, id} = Inline.set_machine_id(-1)
      assert id == -1
    end

    test "accepts large integer values" do
      large_id = 999_999_999
      {:ok, id} = Inline.set_machine_id(large_id)

      assert id == large_id
    end
  end

  describe "behavior compliance" do
    test "implements all required callbacks" do
      # This test ensures the module implements the Snowflake.Adapter behavior
      # Test that the functions are callable
      assert is_boolean(Inline.startable?())
      assert match?({:ok, _}, Inline.next_id())
      assert match?({:ok, _}, Inline.machine_id())
      assert match?({:ok, _}, Inline.set_machine_id(1))
    end

    test "returns correct types for all callbacks" do
      # Test return types match the behavior specification
      assert is_boolean(Inline.startable?())

      assert match?({:ok, _}, Inline.next_id())
      assert match?({:ok, _}, Inline.machine_id())
      assert match?({:ok, _}, Inline.set_machine_id(1))
    end
  end
end
