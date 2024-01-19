defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do
    bucket = start_supervised!(KV.Bucket)
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "key:1") == nil

    KV.Bucket.put(bucket, "key:1", "value 1")
    assert KV.Bucket.get(bucket, "key:1") == "value 1"
  end

  test "deletes the key", %{bucket: bucket} do
    KV.Bucket.put(bucket, "key:1", "value 1")
    assert KV.Bucket.get(bucket, "key:1") == "value 1"

    assert KV.Bucket.delete(bucket, "key:1") == "value 1"
    assert KV.Bucket.get(bucket, "key:1") == nil

    assert KV.Bucket.delete(bucket, "key:1") == nil
  end

  test "are temporary workers" do
    restart_mode = Supervisor.child_spec(KV.Bucket, []).restart
    assert restart_mode == :temporary
  end
end
