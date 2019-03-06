module client.Listener;

import client.Event;

/**
 * Listener for watch config/reistry
 */
public interface Listener
{
    /**
     * Receive event info
     *
     * @param Event 
     */
    void onEvent(Event);
}
