import Config

if System.get_env("CLUSTER") == "true" do
  Node.connect(:"realtime@node2")
  Node.connect(:"realtime@node3")
end
