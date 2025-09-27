defmodule Snowflake.HelperTest do
  use ExUnit.Case, async: true

  alias Snowflake.Helper

  describe "epoch/0" do
    test "returns configured epoch value" do
      # Set a test epoch value
      Application.put_env(:snowflake, :epoch, 1_000_000_000)

      assert Helper.epoch() == 1_000_000_000
    end

    test "returns default epoch value when not configured" do
      # Remove epoch from config
      Application.delete_env(:snowflake, :epoch)

      assert Helper.epoch() == 0
    end
  end

  describe "machine_id/0" do
    test "returns configured machine_id when valid" do
      # Set a valid machine_id
      Application.put_env(:snowflake, :machine_id, 42)

      assert Helper.machine_id() == 42
    end

    test "returns configured machine_id when at boundary (0)" do
      Application.put_env(:snowflake, :machine_id, 0)

      assert Helper.machine_id() == 0
    end

    test "returns configured machine_id when at boundary (1023)" do
      Application.put_env(:snowflake, :machine_id, 1023)

      assert Helper.machine_id() == 1023
    end

    test "falls back to node detection when machine_id is invalid (negative)" do
      Application.put_env(:snowflake, :machine_id, -1)
      Application.put_env(:snowflake, :nodes, ["127.0.0.1"])

      # Should fall back to node detection logic
      result = Helper.machine_id()
      assert is_integer(result)
      assert result >= 0
      assert result <= 1023
    end

    test "falls back to node detection when machine_id is invalid (too large)" do
      Application.put_env(:snowflake, :machine_id, 1024)
      Application.put_env(:snowflake, :nodes, ["127.0.0.1"])

      # Should fall back to node detection logic
      result = Helper.machine_id()
      assert is_integer(result)
      assert result >= 0
      assert result <= 1023
    end

    test "falls back to node detection when machine_id is nil" do
      Application.delete_env(:snowflake, :machine_id)
      Application.put_env(:snowflake, :nodes, ["127.0.0.1"])

      # Should fall back to node detection logic
      result = Helper.machine_id()
      assert is_integer(result)
      assert result >= 0
      assert result <= 1023
    end

    test "returns default machine_id (1023) when no nodes match" do
      Application.delete_env(:snowflake, :machine_id)
      Application.put_env(:snowflake, :nodes, ["nonexistent.node"])

      assert Helper.machine_id() == 1023
    end

    test "returns default machine_id (1023) when nodes config is empty" do
      Application.delete_env(:snowflake, :machine_id)
      Application.put_env(:snowflake, :nodes, [])

      assert Helper.machine_id() == 1023
    end

    test "returns default machine_id (1023) when nodes config is nil" do
      Application.delete_env(:snowflake, :machine_id)
      Application.delete_env(:snowflake, :nodes)

      assert Helper.machine_id() == 1023
    end

    test "finds matching node in nodes list" do
      Application.delete_env(:snowflake, :machine_id)
      Application.put_env(:snowflake, :nodes, ["127.0.0.1", "192.168.1.1", "10.0.0.1"])

      # Should find 127.0.0.1 at index 0
      assert Helper.machine_id() == 0
    end

    test "finds matching node at different position in nodes list" do
      Application.delete_env(:snowflake, :machine_id)
      Application.put_env(:snowflake, :nodes, ["192.168.1.1", "127.0.0.1", "10.0.0.1"])

      # Should find 127.0.0.1 at index 1
      assert Helper.machine_id() == 1
    end
  end
end
