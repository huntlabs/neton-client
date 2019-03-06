module client.Event;

struct Event
{
    enum EventType
    {
        PUT = 0,
        DELETE = 1
    }

    EventType type;
    string key;
    string value;
}
