## Service Discovery

```DLang
NetonOption option = {"127.0.0.1", 50051};
RegistryService service  NetonFactory.createRegistryService(option)
```
### 1.watch service
```DLang
service.subscribe(SERVICE_NAME,new class Listener{
        override void onEvent(Event event)
        {
            logInfo("service listen : ",event);
        }
    });
```
### 2. registry service
```DLang
service.registerInstance(SERVICE_NAME , ADDR , PORT);
service.registerInstance(SERVICE_NAME , ADDR1 , PORT1);
```
### 3. discovery service
```DLang
auto list = service.getAllInstances(SERVICE_NAME);
assert(list.length == 1 && list[0].ip == ADDR  && list[0].port == PORT);
```
### 4. delete service
```DLang
service.deregisterInstance(SERVICE_NAME , ADDR,PORT);
```

##  Configuration management

```DLang
NetonOption option = {"127.0.0.1", 50051};
ConfigService config = NetonFactory.createConfigService(option);
```

### 1.watch config
```DLang
config.addListener(CONFIG_KEY,new class Listener{
        override void onEvent(Event event)
        {
            logInfo("config listen : ",event);
        }
    });
```
### 2. publish config
```DLang
config.publishConfig(CONFIG_KEY,CONFIG_VALUE);
```
### 3. get config
```DLang
auto value = config.getConfig(CONFIG_KEY);
assert(value == CONFIG_VALUE);
```
### 4. remove config
```DLang
config.removeConfig(CONFIG_KEY);
```
