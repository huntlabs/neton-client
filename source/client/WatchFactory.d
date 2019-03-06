module client.WatchFactory;

import client.Watcher;

import etcdserverpb.rpcrpc;
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
