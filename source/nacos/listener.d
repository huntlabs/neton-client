module nacos.listener;

interface Listener
{
    public void receiveConfigInfo(string configInfo);	
}