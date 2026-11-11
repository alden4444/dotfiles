Network Topology
- Physical structure of a network
- Defines how the hardware will be arranged to create the network
- To know:
    - Star
    - Bus
    - Mesh
    - Hybrid

Bus
- All devices connected by one single 'bus' cable
- Terminators on each end stop the signal bouncing back and causing errors
- Each device:
    - Listens to signals
    - Checks data packets for their specific address
    - Ignores data packets it does not recognise
- Advantages:
    - Very cheap to set up
    - Does not rely on other network hardware
- Disadvantages:
    - Not very efficient as not much info can pass through the cable at a time without getting crowded (each device needs to wait for the line to be clear)
    - Not very secure as every device is receiving the same info

Star
- Has a central switch which all other devices connect to
- It is an intelligent device which ensures that traffic only goes to the intended device
- Traffic (packets) on a star topology is handled differently depending on the device used as the central node:
    - A hub will send traffic to all devices on the network, if the address in the packet matches a device it will be accepted, otherwise it is ignored
    - A switch will only send traffic to devices on the network where the address in the packet is a match
- Advantages:
    - If one cable fails, the rest of the network still works
    - A problem with one device won't affect others
    - More reliable
- Disadvantages:
    - The central switch is a single point of failure
    - If the switch stops working, all devices lose connection to the network and its resources
    - Can be expensive to install due to the switch and extra cabling

Mesh
- All computers are connected to all other computers
- Known as full mesh network
- LANs can make use of mesh networks however they are more commonly seen in IoT devices such as wearable technology and smart home devices
- Traffic (packets) on a mesh topology can follow two different methods:
    - Routing - devices are given routing logic (act like a router) to ensure packets are sent to the correct device in the shortest route
    - Flooding - all packets are sent to all devices, this can cause performance issues
- Advantages:
    - If one cable fails, the network still works - data can use an alternate route
    - Provides high fault tolerance
    - Very reliable
- Disadvantages:
    - Requires lots of hardware
    - High cost to set up
    - Hard to scale

Hybrid
- Mix of two or more different topologies
- Used when there is a need to join different networks together
- Advantages:
    - When combining networks, each keeps its existing setup
    - Combines the strengths of multiple topologies
    - Flexible; different parts of the network can be optimised for different needs
    - Scalable
    - Reliable
- Disadvantages:
    - Complex to design
    - Expensive to set up / maintain
    - Troubleshooting can be more difficult
