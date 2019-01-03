module nacos.eventlistener;
import nacos.event;

interface EventListener
{
    void onEvent(Event e);
}