package com.admalledd.CCTurtleGlobalPos;


import java.lang.reflect.Field;
import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import dan200.computercraft.api.lua.IComputerSystem;
import dan200.computercraft.api.lua.ILuaAPI;
import dan200.computercraft.api.lua.LuaFunction;
import dan200.computercraft.api.turtle.ITurtleAccess;
import dan200.computercraft.core.computer.Computer;
import dan200.computercraft.shared.computer.core.ServerComputer;
import dan200.computercraft.shared.pocket.core.PocketServerComputer;
import dan200.computercraft.shared.turtle.apis.TurtleAPI;
import net.minecraft.util.Direction;
import net.minecraft.util.math.BlockPos;


public class GlobalPosAPI implements ILuaAPI
{
    private final ServerComputer computer;
    private ITurtleAccess turtle;
    private boolean didLazyLoad = false;
    private static final Logger LOGGER = LogManager.getLogger();
    public GlobalPosAPI( ServerComputer computer )
    {
        this.computer = computer;
        this.turtle = null;
    }
	@Override
	public String[] getNames()
	{
		return new String[] { "GlobalPosAPI" };
	}
	private void doLazyLoad() 
	{
		if (didLazyLoad == false)
    	{
    		didLazyLoad = true;
    		try
    		{
    			//also: 
    			//Attempt to get turtle brain API via Computer.(ComputerExecutor)executor.apis[TurtleAPI]
    			// if we succeed, then use that instead of ServerComputer
    			// ServerComputer doesn't provide .getDirection() is why
    			Field f_1;
    			Class comp_class = computer.getClass();
    			if (comp_class == PocketServerComputer.class)
    			{
    				f_1 = computer.getClass().getSuperclass().getDeclaredField("m_computer");
    			}
    			else if (comp_class == ServerComputer.class)
    			{
    				f_1 = computer.getClass().getDeclaredField("m_computer");
    			}
    			else 
    			{
    				//NB: unable to reliably reflect other non CC:T computers, ignore anything more fancy.
    				LOGGER.info("GlobalPosAPI.doLazyLoad(): unknown child type, you will only have position. child type was:"+comp_class.getTypeName());
    				return;
    			}
    			f_1.setAccessible(true);
    			Computer comp = (Computer)f_1.get(computer); 
    			Field f_4 = comp.getClass().getDeclaredField("executor");
    			f_4.setAccessible(true);
    			Object executor = f_4.get(comp);
    			Field f_5 = executor.getClass().getDeclaredField("apis");
    			f_5.setAccessible(true);
    			List<ILuaAPI> apis = (List<ILuaAPI>)f_5.get(executor);
    			for (ILuaAPI iLuaAPI : apis) {
    				if (iLuaAPI instanceof TurtleAPI) {
    					Field f_6  = iLuaAPI.getClass().getDeclaredField("turtle");
    					f_6.setAccessible(true);
    					turtle = (ITurtleAccess)f_6.get(iLuaAPI);
    					LOGGER.info("GlobalPosAPIFactory found a turtle, pos+dir available.");
    				}
    			}
    		}
    		catch (Exception e) 
    		{

    			LOGGER.error("GlobalPosAPI LazyInit couldn't scan existing APIs for turtle-ness", e);
    		}
    	}
	}
	/**
     * Get the position of the current computer. Returns nil's when data isn't available
     *
     * @return The block's position.
     * @cc.treturn number This computer's x position.
     * @cc.treturn number This computer's y position.
     * @cc.treturn number This computer's z position.
     * @cc.treturn string This computer's direction (nil if not available, only on turtles)
     */
    @LuaFunction
    public final Object[] getBlockPosition()
    {
    	doLazyLoad();
    	
        // This is probably safe to do on the Lua thread. Probably.
    	if (turtle != null)
    	{
    		BlockPos pos = turtle.getPosition();
    		Direction dir = turtle.getDirection();
    		return new Object[] { pos.getX(), pos.getY(), pos.getZ(), dir.name() };
    	}
    	else if (computer != null)
    	{
            BlockPos pos = computer.getPosition();
            return new Object[] { pos.getX(), pos.getY(), pos.getZ(), null };	
    	}
    	else
    	{
    		return new Object[] { null, null, null, null };
    	}
    }
}
