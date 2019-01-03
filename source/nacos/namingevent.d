module nacos.namingevent;

import nacos.event;
import nacos.instance;

class NamingEvent : Event 
{
    string serviceName;
    Instance[] ins;

    this(string serviceName , Instance[] ins)
    {
        this.serviceName = serviceName;
        this.ins = ins;
    }
    string  getServceName()
    {
        return serviceName;
    }
    Instance[] getInstances()
    {
        return ins;
    }
}
