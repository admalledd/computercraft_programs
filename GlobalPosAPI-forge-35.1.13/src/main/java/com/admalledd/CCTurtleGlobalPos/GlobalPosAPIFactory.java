package com.admalledd.CCTurtleGlobalPos;


//import dan200.computercraft.api.*;
import dan200.computercraft.api.lua.ILuaAPIFactory;
import dan200.computercraft.api.turtle.ITurtleAccess;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;

import dan200.computercraft.api.lua.IComputerSystem;
import dan200.computercraft.api.lua.ILuaAPI;

import dan200.computercraft.core.apis.IAPIEnvironment;
import dan200.computercraft.core.computer.Computer;
//import dan200.computercraft.core.computer.ComputerExecutor; //not introspectable here
import dan200.computercraft.core.computer.IComputerEnvironment;
import dan200.computercraft.shared.computer.core.ServerComputer;
import dan200.computercraft.shared.turtle.apis.TurtleAPI;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;


public class GlobalPosAPIFactory implements ILuaAPIFactory
{
    private static final Logger LOGGER = LogManager.getLogger();
	public ILuaAPI create(IComputerSystem computer)
	{
		try {

			//we need the "ServerComputer" instance if exists for this
			// to get to the "ServerComputer.getBlockPos()" method.
			// via IComputerSystem.environment.computer.m_environment == ServerComputer
			Field f_1 = computer.getClass().getDeclaredField("environment");
			f_1.setAccessible(true);
			IAPIEnvironment env = (IAPIEnvironment)f_1.get(computer);
			Field f_2 = env.getClass().getDeclaredField("computer");
			f_2.setAccessible(true);
			Computer comp = (Computer)f_2.get(env);
			Field f_3 = comp.getClass().getDeclaredField("m_environment");
			f_3.setAccessible(true);
			IComputerEnvironment servComp = (IComputerEnvironment)f_3.get(comp);
			if (servComp instanceof ServerComputer) {
				//LOGGER.info("GlobalPosAPIFactory found a positional comp, we at least have pos");
				return new GlobalPosAPI((ServerComputer)servComp);
			}
			LOGGER.info("GlobalPosAPIFactory didn't find a backing LuaComputer");
			return null;
			
		}
		catch (Exception e)
		{
			LOGGER.error("GlobalPosAPIFactory couldn't connect to the LuaComputer for position state...", e);
			return null;
		}
	}
}