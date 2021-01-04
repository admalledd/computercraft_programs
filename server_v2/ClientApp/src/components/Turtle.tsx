
import React, { createContext, Dispatch, SetStateAction, useEffect, useState, useRef, useMemo } from 'react';
import { EventEmitter } from 'events';
import Button from '@material-ui/core/Button';
import ButtonGroup, { ButtonGroupProps } from '@material-ui/core/ButtonGroup';
import ArrowDownward from '@material-ui/icons/ArrowDownward';
import ArrowUpward from '@material-ui/icons/ArrowUpward';
import CircularProgress, { CircularProgressProps } from '@material-ui/core/CircularProgress';
import Box from '@material-ui/core/Box';
import Typography from '@material-ui/core/Typography';
import { MuiThemeProvider, createMuiTheme, makeStyles } from '@material-ui/core/styles';
import Dialog from '@material-ui/core/Dialog';
import DialogContent from '@material-ui/core/DialogContent';
import DialogTitle from '@material-ui/core/DialogTitle';
import TextField from '@material-ui/core/TextField';
import InputAdornment from '@material-ui/core/InputAdornment';
import SvgIcon from '@material-ui/core/SvgIcon';
import IconButton from '@material-ui/core/IconButton';
import DialogActions from '@material-ui/core/DialogActions/DialogActions';

import { DialogContentText } from '@material-ui/core';

//import Inventory from './Inventory';
//import TurtleSwitcher from './TurtleSwitcher';

export interface TurtlePageProps {
	turtle: Turtle;
	enabled: boolean;
	setDisableEvents: (_: boolean) => void;
}

export enum BlockDirection { FORWARD, UP, DOWN }
export enum Direction { NORTH, EAST, SOUTH, WEST }
export enum Side { LEFT, RIGHT }

interface Slot {
	count: number;
	name: string;
	damage: number;
}

export class Turtle extends EventEmitter {
	inventory: (Slot | null)[] = [];
	selectedSlot: number;
	x: number;
	y: number;
	z: number;
	d: Direction;
	label: string;
	fuel: number;
	maxFuel: number;
	id: number;
	mining: boolean = false;

	constructor(json: any) {
		super();
		this.inventory = json.inventory;
		this.selectedSlot = json.selectedSlot;
		this.x = json.x;
		this.y = json.y;
		this.z = json.z;
		this.d = json.d;
		this.fuel = json.fuel;
		this.maxFuel = json.maxFuel;
		this.label = json.label;
		this.id = json.id;
	}
	
	toJSON(): object {
		return {
			label: this.label,
			inventory: this.inventory,
			selectedSlot: this.selectedSlot,
			x: this.x,
			y: this.y,
			z: this.z,
			d: this.d,
			fuel: this.fuel,
			maxFuel: this.maxFuel,
			id: this.id,
			mining: this.mining
		};
	}

	exec<T>(command: string): Promise<T> {
		//TODO: SignalR Hub-ize
		return new Promise(r => {
			console.log("exec:"+command);
			// const nonce = getNonce();
			// this.ws.send(JSON.stringify({
			// 	type: 'eval',
			// 	function: `return ${command}`,
			// 	nonce
			// }));

			// const listener = (resp: string) => {
			// 	try {
			// 		let res = JSON.parse(resp);
			// 		if (res?.nonce === nonce) {
			// 			r(res.data);
			// 			this.ws.off('message', listener);
			// 		}
			// 	} catch (e) { }
			// };

			// this.ws.on('message', listener);
		});
	}


	async forward(): Promise<boolean> {
		let r = await this.exec<boolean>('turtle.forward()');
		if (r) {
			this.fuel--;
			await this.updatePosition('forward');
		}
		return r;
	}
	async back(): Promise<boolean> {
		let r = await this.exec<boolean>('turtle.back()');
		if (r) {
			this.fuel--;
			await this.updatePosition('back');
		}
		return r;
	}
	async up(): Promise<boolean> {
		let r = await this.exec<boolean>('turtle.up()');
		if (r) {
			this.fuel--;
			await this.updatePosition('up');
		}
		return r;
	}
	async down(): Promise<boolean> {
		let r = await this.exec<boolean>('turtle.down()');
		if (r) {
			this.fuel--;
			await this.updatePosition('down');
		}
		return r;
	}
	async turnLeft(): Promise<boolean> {
		let r = await this.exec<boolean>('turtle.turnLeft()');
		if (r) {
			await this.updatePosition('left');
		}
		return r;
	}
	async turnRight(): Promise<boolean> {
		let r = await this.exec<boolean>('turtle.turnRight()');
		if (r) {
			await this.updatePosition('right');
		}
		return r;
	}

	private parseDirection(prefix: string, direction: BlockDirection): string {
		switch (direction) {
			case BlockDirection.FORWARD:
				return prefix;
			case BlockDirection.UP:
				return prefix + 'Up';
			case BlockDirection.DOWN:
				return prefix + 'Down';
		}
	}

	private async updateInventory() {
		this.inventory = await this.exec<Slot[]>('{' + new Array(16).fill(0).map((_, i) => `turtle.getItemDetail(${i + 1})`).join(', ') + '}');
		while (this.inventory.length < 16) {
			this.inventory.push(null);
		}
		this.emit('update');
	}

	private async updateFuel() {
		this.emit('update');
	}

	private getDirectionDelta(dir: Direction): [number, number] {
		if (dir === Direction.NORTH) return [0, -1];
		else if (dir === Direction.EAST) return [1, 0];
		else if (dir === Direction.SOUTH) return [0, 1];
		else if (dir === Direction.WEST) return [-1, 0];
		return [0, 0];
	}

	private async updatePosition(move: string) {
		//TODO: signalR-ize
		return;
		/*
		let deltas = this.getDirectionDelta(this.d);
		switch (move) {
			case 'up':
				this.y++;
				break;
			case 'down':
				this.y--;
				break;
			case 'forward':
				this.x += deltas[0];
				this.z += deltas[1];
				break;
			case 'back':
				this.x -= deltas[0];
				this.z -= deltas[1];
				break;
			case 'left':
				this.d += 3;
				this.d %= 4;
				break;
			case 'right':
				this.d++;
				this.d %= 4;
				break;
		}
		this.world.updateTurtle(this, this.x, this.y, this.z, this.d);
		await this.updateBlock();
		this.emit('update');*/
	}

	private async updateBlock() {
		let deltas = this.getDirectionDelta(this.d);
		let { forward, up, down } = await this.exec<{ forward: any, up: any, down: any }>('{down=select(2,turtle.inspectDown()), up=select(2,turtle.inspectUp()), forward=select(2,turtle.inspect())}');
		//this.world.updateBlock(this.x, this.y - 1, this.z, down);
		//this.world.updateBlock(this.x, this.y + 1, this.z, up);
		//this.world.updateBlock(this.x + deltas[0], this.y, this.z + deltas[1], forward);
	}

	async dig(direction: BlockDirection) {
		let r = await this.exec<boolean>(`turtle.${this.parseDirection('dig', direction)}()`);
		await this.updateInventory();
		await this.updateBlock();
		return r;
	}
	async place(direction: BlockDirection, signText?: string) {
		let r = await this.exec<boolean>(`turtle.${this.parseDirection('place', direction)}(${signText ? ('"' + signText + '"') : ''})`);
		await this.updateInventory();
		await this.updateBlock();
		return r;
	}
	async drop(direction: BlockDirection, count?: number) {
		let r = await this.exec<boolean>(`turtle.${this.parseDirection('drop', direction)}(${(typeof count === 'number') ? count.toString() : ''})`);
		await this.updateInventory();
		return r;
	}
	async suck(direction: BlockDirection, count?: number) {
		let r = await this.exec<boolean>(`turtle.${this.parseDirection('suck', direction)}(${(typeof count === 'number') ? count.toString() : ''})`);
		await this.updateInventory();
		return r;
	}
	async refuel(count?: number) {
		let r = await this.exec<boolean>(`turtle.refuel(${(typeof count === 'number') ? count.toString() : ''})`);
		this.fuel = await this.exec<number>('turtle.getFuelLevel()');
		await this.updateInventory();
		return r;
	}
	async equip(side: 'left' | 'right') {
		let r;
		if (side === 'left')
			r = await this.exec<boolean>('turtle.equipLeft()');
		else
			r = await this.exec<boolean>('turtle.equipRight()');
		await this.updateInventory();
		return r;
	}
	async selectSlot(slot: number) {
		if (slot > 0 && slot < 17) {
			this.selectedSlot = slot;
			let r = await this.exec<boolean>(`turtle.select(${slot})`);
			this.emit('update');
			return r;
		}
		return false;
	}
	async refresh() {
		await this.updateInventory();
		await this.updateBlock();
		this.selectedSlot = await this.exec<number>('turtle.getSelectedSlot()');
		this.maxFuel = await this.exec<number>('turtle.getFuelLimit()');
		this.fuel = await this.exec<number>('turtle.getFuelLevel()');
	}
	async moveItems(slot: number, amount: 'all' | 'half' | 'one') {
		let max = this.inventory[this.selectedSlot - 1]?.count;
		if (max) {
			let count = 1;
			if (amount === 'all') count = max;
			else if (amount === 'half') count = Math.floor(max / 2);
			let r = await this.exec<boolean>(`turtle.transferTo(${slot}, ${count})`);
			await this.updateInventory();
			return r;
		}
		return false;
	}

	async craft(amount: 'all' | 'one') {
		let r = await this.exec<boolean>(`turtle.craft(${amount === 'one' ? '1' : ''})`);
		await this.updateInventory();
		return r;
	}
}


const useStyles = makeStyles(theme => ({
	toolbar: {
		display: 'flex',
		justifyContent: 'start',
		alignItems: 'center',
		background: '#252525',
		height: 100,
		width: '100%',
	},
	groups: {
		display: 'flex',
		alignItems: 'center',
		justifyContent: 'start',
		'&>*': {
			marginLeft: theme.spacing(1),
			marginRight: theme.spacing(1),
		}
	}
}));


function CircularProgressWithLabel(props: CircularProgressProps & { label: any }) {
	return (
		<Box style={{ position: 'relative', display: 'inline-flex' }}>
			<CircularProgress variant="static" {...props} />
			<Box style={{ top: 0, left: 0, bottom: 0, right: 0, position: 'absolute', display: 'flex', alignItems: 'center', justifyContent: 'center' }}			>
				<Typography variant="caption" component="div" color="textSecondary">{props.label}</Typography>
			</Box>
		</Box>
	);
}


export default function TurtlePage({ turtle, enabled, setDisableEvents }: TurtlePageProps) {
	const [signText, setSignText] = useState<string | null>(null);
	const [commandText, setCommandText] = useState<string | null>(null);
	const [commandResult, setCommandResult] = useState<string | null>(null);
	const [mineLength, setMineLength] = useState<string>('');
	const currentSignDirection = useRef<BlockDirection>(BlockDirection.FORWARD);
	const classes = useStyles({ enabled });

	const placeBlock = (dir: BlockDirection) => {
		if (turtle.inventory[turtle.selectedSlot - 1]?.name === 'minecraft:sign') {
			currentSignDirection.current = dir;
			setSignText('');
		} else {
			turtle.place(dir);
		}
	}

	useEffect(() => {
		setDisableEvents(signText !== null || commandText !== null || commandResult !== null);
	}, [signText, commandText]);

	return (
		<>
			<Dialog disableBackdropClick open={signText !== null} onClose={() => setSignText(null)}>
				<DialogTitle>Sign Text</DialogTitle>
				<DialogContent>
					<TextField value={signText || ''} onChange={(ev) => setSignText(ev.target.value)} variant="outlined" />
				</DialogContent>
				<DialogActions>
					<Button onClick={() => setSignText(null)}>Cancel</Button>
					<Button onClick={() => {
						setSignText(null);
						turtle.place(currentSignDirection.current, signText!);
					}}>Place</Button>
				</DialogActions>
			</Dialog>
			<Dialog disableBackdropClick open={commandText !== null} onClose={() => setCommandText(null)}>
				<DialogTitle>Command</DialogTitle>
				<DialogContent>
					<TextField value={commandText || ''} onChange={(ev) => setCommandText(ev.target.value)} variant="outlined" />
				</DialogContent>
				<DialogActions>
					<Button onClick={() => setCommandText(null)}>Cancel</Button>
					<Button onClick={() => {
						setCommandText(null);
						turtle.exec<string>(commandText!).then((res) => setCommandResult(res));
					}}>Run</Button>
				</DialogActions>
			</Dialog>
			<Dialog disableBackdropClick open={commandResult !== null} onClose={() => setCommandResult(null)}>
				<DialogTitle>Command Result</DialogTitle>
				<DialogContent>
					<DialogContentText>{commandResult}</DialogContentText>
				</DialogContent>
				<DialogActions>
					<Button onClick={() => setCommandResult(null)}>Ok</Button>
				</DialogActions>
			</Dialog>
			<div className={classes.toolbar} style={{ display: enabled ? undefined : "none" }}>
				{/* <Inventory turtle={turtle} /> */}
				<div className={classes.groups}>
					<TurtleButtonGroup turtle={turtle} func="dig" color='#e74c3c' />
					<ColoredButtonGroup groupColor='#e67e22' size="small" orientation="vertical">
						<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => placeBlock(BlockDirection.UP)}><ArrowUpward /></Button>
						<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => placeBlock(BlockDirection.FORWARD)}>
							place
						</Button>
						<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => placeBlock(BlockDirection.DOWN)}><ArrowDownward /></Button>
					</ColoredButtonGroup>
					<TurtleButtonGroup turtle={turtle} func="suck" color='#f1c40f' />
					<TurtleButtonGroup turtle={turtle} func="drop" color='#2ecc71' />
					<ColoredButtonGroup size="small" orientation="vertical" groupColor='#3498db'>
						<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => turtle.craft('all')}>Craft All</Button>
						<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => turtle.craft('one')}>Craft One</Button>
						<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => turtle.refuel()}>Refuel</Button>
					</ColoredButtonGroup>
					<ColoredButtonGroup size="small" orientation="vertical" groupColor='#9b59b6'>
						<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => turtle.refresh()}>Refresh Info</Button>
						{/* <Button tabIndex="-1" variant="outlined" color="primary" onClick={() => turtle.undergoMitosis()}>Undergo Mitosis</Button> */}
						<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => setCommandText('')}>Run Command</Button>
					</ColoredButtonGroup>
					{/* <TextField
						label="Mine Tunnel"
						variant="outlined"
						value={mineLength}
						onChange={(ev) => setMineLength(ev.target.value)}
						InputProps={{
							endAdornment: <InputAdornment position="end">
								<IconButton onClick={() => turtle.mineTunnel('down', parseInt(mineLength))}>
									<ArrowDownward />
								</IconButton>
								<IconButton onClick={() => turtle.mineTunnel('forward', parseInt(mineLength))}>
									<SvgIcon>
										<path d="M14.79,10.62L3.5,21.9L2.1,20.5L13.38,9.21L14.79,10.62M19.27,7.73L19.86,7.14L19.07,6.35L19.71,5.71L18.29,4.29L17.65,4.93L16.86,4.14L16.27,4.73C14.53,3.31 12.57,2.17 10.47,1.37L9.64,3.16C11.39,4.08 13,5.19 14.5,6.5L14,7L17,10L17.5,9.5C18.81,11 19.92,12.61 20.84,14.36L22.63,13.53C21.83,11.43 20.69,9.47 19.27,7.73Z" />
									</SvgIcon>
								</IconButton>
								<IconButton onClick={() => turtle.mineTunnel('up', parseInt(mineLength))}>
									<ArrowUpward />
								</IconButton>
							</InputAdornment>
						}}
					/> */}
				</div>
				{/* <TurtleSwitcher /> */}
				<CircularProgressWithLabel variant="determinate" value={turtle.fuel / turtle.maxFuel * 100} label={turtle.fuel} />
			</div>
		</>
	);
}

interface TurtleButtonGroupProps {
	turtle: Turtle;
	func: 'place' | 'dig' | 'drop' | 'suck';
	color: string;
}

function ColoredButtonGroup({ groupColor, ...props }: { groupColor: string } & ButtonGroupProps) {
	const theme = useMemo(() => createMuiTheme({
		palette: {
			primary: {
				main: groupColor
			}
		},
	}), [groupColor]);
	return (
		<MuiThemeProvider theme={theme}>
			<ButtonGroup {...props} />
		</MuiThemeProvider >
	);

}

function TurtleButtonGroup({ turtle, func, color }: TurtleButtonGroupProps) {
	return (
		<ColoredButtonGroup groupColor={color} size="small" orientation="vertical">
			<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => turtle[func](BlockDirection.UP)}><ArrowUpward /></Button>
			<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => turtle[func](BlockDirection.FORWARD)}>
				{func}
			</Button>
			<Button tabIndex="-1" variant="outlined" color="primary" onClick={() => turtle[func](BlockDirection.DOWN)}><ArrowDownward /></Button>
		</ColoredButtonGroup>
	);
}
