module neton.client.WatchFactory;

import neton.client.Watcher;

import neton.protocol.netonrpc;
import grpc;

class WatchFactory
{
    static Watcher createConfigWatcher(Channel channel, string configPrefix = "/config")
    {
        auto client = new WatchClient(channel);
        auto stream = client.Watch();
        return new Watcher(stream, configPrefix);
    }

    static Watcher createRegistryWatcher(Channel channel, string servicePrefix = "/service")
    {
        auto client = new WatchClient(channel);
        auto stream = client.Watch();
        return new Watcher(stream, servicePrefix);
    }
}
