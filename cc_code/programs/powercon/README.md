


Fusion Reactor Power control
============================


The parts:

* Power Control Client: This hooks into one ME network and manages the in-out flow of:
    * Deuterium: I/O from reactors, closed loop.
    * Tritium: I/O from reactors, closed loop.
    * Plasma: Out only, each client must be self sustaining.
    * Empty cells: I/O from master. When low on cells, request more. When in surplus give back to master.
    * Online/Offline: If requested from master we are allowed to go to "Idle mode" where we keep at least 50% plasma capacity. (Because each client has its own processing and reactors in a closed loop we can never let them run dry...)

* Monitor Client: This hooks into the master computer and outputs the current status information about the reactors
    * total plasma
    * PCC statuses (which/how many are active)
    * plasma input
    * plasma out (estimate total EU usage?)

* Control Client: This hooks into the master computer as well as the master message system
    * Able to toggle on/off certain processing (EG: laser drills)
    * Able to toggle on/off manually some PCCs


* Power Control