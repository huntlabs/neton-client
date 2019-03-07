module neton.client.NetonFactory;

import neton.client.config.ConfigService;
import neton.client.registry.RegistryService;
import neton.client.NetonOption;
import grpc;

class NetonFactory
{
    static ConfigService createConfigService(NetonOption option)
    {
        auto channel = new GrpcClient(option.ip, option.port);
        return new ConfigService(channel);
    }

    static RegistryService createRegistryService(NetonOption option)
    {
        auto channel = new GrpcClient(option.ip, option.port);
        return new RegistryService(channel);
    }
}