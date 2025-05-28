export type AnimatablePrimitive = number | vector | Vector3

export type AnimatableType = AnimatablePrimitive | Vector2 | CFrame | Color3 | UDim | UDim2 | Rect

export type Animatable = AnimatableType | { [any]: AnimatablePrimitive }

return {}
