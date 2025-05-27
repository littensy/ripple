local React = require(script.Parent.Parent.react)

type CoreReactBinding<T> = {
	getValue: (self: CoreReactBinding<T>) -> T,
	_source: string?,
}

type ReactBindingMap = {
	map: <T, U>(self: CoreReactBinding<T> & ReactBindingMap, (T) -> U) -> ReactBindingMap & CoreReactBinding<U>,
}

export type Binding<T> = CoreReactBinding<T> & ReactBindingMap

return React
