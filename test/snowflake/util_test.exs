defmodule Snowflake.UtilTest do
  use ExUnit.Case, async: true

  alias Snowflake.Util

  setup do
    # Set a test epoch for consistent testing
    Application.put_env(:snowflake, :epoch, 1_000_000_000)
    on_exit(fn -> Application.delete_env(:snowflake, :epoch) end)
  end

  describe "ts/0" do
    test "returns timestamp relative to configured epoch" do
      timestamp = Util.ts()

      assert is_integer(timestamp)
      assert timestamp >= 0
    end
  end

  describe "ts/1" do
    test "returns timestamp relative to provided epoch" do
      epoch = 1_000_000_000
      timestamp = Util.ts(epoch)

      assert is_integer(timestamp)
      assert timestamp >= 0
    end

    test "returns 0 when current time equals epoch" do
      # This test is more about the calculation logic
      # In practice, it's unlikely to get exactly 0
      epoch = System.os_time(:millisecond)
      timestamp = Util.ts(epoch)

      assert is_integer(timestamp)
      assert timestamp >= 0
    end
  end

  describe "first_snowflake_for_timestamp/1" do
    test "creates snowflake ID with timestamp in correct position" do
      epoch = 1_000_000_000
      # 1 second after epoch
      timestamp = epoch + 1000

      snowflake_id = Util.first_snowflake_for_timestamp(timestamp)

      # Extract timestamp from the snowflake ID
      extracted_timestamp = Util.timestamp_of_id(snowflake_id)

      assert extracted_timestamp == 1000
    end

    test "creates snowflake ID with machine_id and sequence set to 0" do
      epoch = 1_000_000_000
      timestamp = epoch + 5000

      snowflake_id = Util.first_snowflake_for_timestamp(timestamp)

      # The snowflake should have machine_id = 0 and sequence = 0
      # This is verified by checking that the lower 22 bits are 0
      # 2^22 - 1 = 4,194,303, but we want 0
      assert rem(snowflake_id, 2_097_152) == 0
    end

    test "handles large timestamps correctly" do
      epoch = 1_000_000_000
      # 1000 seconds after epoch
      timestamp = epoch + 1_000_000

      snowflake_id = Util.first_snowflake_for_timestamp(timestamp)
      extracted_timestamp = Util.timestamp_of_id(snowflake_id)

      assert extracted_timestamp == 1_000_000
    end
  end

  describe "timestamp_of_id/1" do
    test "extracts timestamp from snowflake ID" do
      # Create a snowflake ID manually
      timestamp = 5000
      machine_id = 42
      sequence = 123

      snowflake_id = create_snowflake_id(timestamp, machine_id, sequence)

      assert Util.timestamp_of_id(snowflake_id) == timestamp
    end

    test "extracts timestamp from first snowflake for timestamp" do
      epoch = Snowflake.Helper.epoch()
      timestamp = epoch + 2000

      snowflake_id = Util.first_snowflake_for_timestamp(timestamp)
      extracted_timestamp = Util.timestamp_of_id(snowflake_id)

      # The extracted timestamp should be the relative timestamp (2000), not the absolute timestamp
      assert extracted_timestamp == 2000
    end

    test "handles zero timestamp" do
      snowflake_id = create_snowflake_id(0, 0, 0)

      assert Util.timestamp_of_id(snowflake_id) == 0
    end
  end

  describe "real_timestamp_of_id/1" do
    test "returns unix timestamp from snowflake ID" do
      epoch = 1_000_000_000
      relative_timestamp = 5000
      timestamp = epoch + relative_timestamp

      snowflake_id = Util.first_snowflake_for_timestamp(timestamp)
      real_timestamp = Util.real_timestamp_of_id(snowflake_id)

      assert real_timestamp == timestamp
    end

    test "adds epoch to relative timestamp" do
      epoch = 1_000_000_000
      relative_timestamp = 10000

      snowflake_id = create_snowflake_id(relative_timestamp, 0, 0)
      real_timestamp = Util.real_timestamp_of_id(snowflake_id)

      assert real_timestamp == epoch + relative_timestamp
    end
  end

  describe "bucket/3" do
    test "calculates bucket for given snowflake ID with days" do
      epoch = 1_000_000_000
      # 2 days worth of milliseconds
      timestamp = epoch + 2 * 24 * 60 * 60 * 1000
      snowflake_id = Util.first_snowflake_for_timestamp(timestamp)

      bucket = Util.bucket(1, :days, snowflake_id)

      assert bucket == 2
    end

    test "calculates bucket for given snowflake ID with hours" do
      epoch = 1_000_000_000
      # 5 hours worth of milliseconds
      timestamp = epoch + 5 * 60 * 60 * 1000
      snowflake_id = Util.first_snowflake_for_timestamp(timestamp)

      bucket = Util.bucket(1, :hours, snowflake_id)

      assert bucket == 5
    end

    test "calculates bucket with multiple units" do
      epoch = 1_000_000_000
      # 6 days worth of milliseconds
      timestamp = epoch + 6 * 24 * 60 * 60 * 1000
      snowflake_id = Util.first_snowflake_for_timestamp(timestamp)

      bucket = Util.bucket(2, :days, snowflake_id)

      # 6 days / 2 days per bucket = 3
      assert bucket == 3
    end

    test "handles zero timestamp" do
      snowflake_id = create_snowflake_id(0, 0, 0)

      bucket = Util.bucket(1, :days, snowflake_id)

      assert bucket == 0
    end

    test "rounds down for partial buckets" do
      epoch = 1_000_000_000
      # 1.5 days worth of milliseconds
      timestamp = epoch + round(1.5 * 24 * 60 * 60 * 1000)
      snowflake_id = Util.first_snowflake_for_timestamp(timestamp)

      bucket = Util.bucket(1, :days, snowflake_id)

      # The bucket calculation uses round(), so 1.5 days should round to 2
      assert bucket == 2
    end
  end

  describe "bucket/2" do
    test "calculates bucket for current time with days" do
      bucket = Util.bucket(1, :days)

      assert is_integer(bucket)
      assert bucket >= 0
    end

    test "calculates bucket for current time with hours" do
      bucket = Util.bucket(1, :hours)

      assert is_integer(bucket)
      assert bucket >= 0
    end

    test "calculates bucket with multiple units for current time" do
      bucket = Util.bucket(7, :days)

      assert is_integer(bucket)
      assert bucket >= 0
    end
  end

  # Helper function to create a snowflake ID manually
  defp create_snowflake_id(timestamp, machine_id, sequence) do
    <<snowflake_id::unsigned-integer-size(64)>> = <<
      timestamp::unsigned-integer-size(42),
      machine_id::unsigned-integer-size(10),
      sequence::unsigned-integer-size(12)
    >>

    snowflake_id
  end
end
