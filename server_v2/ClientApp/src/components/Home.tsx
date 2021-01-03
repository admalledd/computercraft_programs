import React, { Component, createContext, Dispatch, SetStateAction, useEffect, useState } from 'react';
import { makeStyles } from '@material-ui/core';

import Chat from './Chat';
import TurtlePage, {Turtle} from './Turtle'


const useStyles = makeStyles(() => ({
	root: {
		width: '100vw',
		height: '100vh',
		display: 'flex',
		flexDirection: 'column',
		justifyContent: 'center',
		alignItems: 'center',
	},
	world: {
		width: '100%',
		height: 'calc(100% - 100px)'
	},
}));

interface MyWindow extends Window {
	exec<T>(index: number, code: string, ...args: any[]): Promise<T>;
	refreshData(): void;
	setWorld: Function;
	setTurtles: Function;
}

declare var window: MyWindow;

export const TurtleContext = createContext<[number, Dispatch<SetStateAction<number>>, Turtle[]]>([-1, () => { }, []] as any);

export default function Home() {
  const displayName = Home.name;


  const classes = useStyles();
	const [turtles, setTurtles] = useState<Turtle[]>([]);
	//const [world, setWorld] = useState<World>({});
	const [turtleId, setTurtleId] = useState<number>(-1);

	useEffect(() => {
		window.setTurtles = (array: any[]) => {
			setTurtles(array.map(turtle => new Turtle(turtle)));
		};
		//window.setWorld = setWorld;

		//window.refreshData();

  //}, [setTurtles, setWorld]);
  }, [setTurtles]);

	const [disableEvents, setDisableEvents] = useState(false);
  
  return (
    <>
      <TurtlePage setDisableEvents={setDisableEvents} enabled={true} key={1234} turtle={new Turtle(
        {inventory : []}
      ) } />
      <Chat />
    </>
  );
  
  
  
}
