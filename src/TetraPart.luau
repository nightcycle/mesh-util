--!strict
--!native
local Package = script.Parent
local Packages = Package.Parent

-- Packages
local GeometryUtil = require(Packages:WaitForChild("GeometryUtil"))

type Point = GeometryUtil.Point
type Vertex = GeometryUtil.Vertex
type Normal = GeometryUtil.Normal
type Axis = GeometryUtil.Axis
type Line = GeometryUtil.Line
type Surface = GeometryUtil.Surface
type Radian = GeometryUtil.Radian

local normals: {[string]: Enum.NormalId} = {
	Top = Enum.NormalId.Top,
	Bottom = Enum.NormalId.Bottom,
	Back = Enum.NormalId.Back,
	Front = Enum.NormalId.Front,
	Right = Enum.NormalId.Right,
	Left = Enum.NormalId.Left,
}


function getSurfaceCFrame(part: BasePart, lnormal: Normal): CFrame
	local UP = Vector3.new(0, 1, 0)
	local BACK = Vector3.new(0, 0, 1)
	local EXTRASPIN = CFrame.fromEulerAnglesXYZ(math.pi / 2, 0, 0)

	local function getTranstionBetween(a: Normal, b: Normal, pitchAxis: Axis)
		local dot: number = a:Dot(b)
		if dot > 0.99999 then
			return CFrame.new()
		elseif dot < -0.99999 then
			return CFrame.fromAxisAngle(pitchAxis, math.pi)
		end
		return CFrame.fromAxisAngle(a:Cross(b), math.acos(dot))
	end

	local transition: CFrame = getTranstionBetween(UP, lnormal, BACK)
	return part.CFrame * transition * EXTRASPIN
end

function getWorldPosition(part: BasePart, offset: Vector3): Point
	return (part.CFrame * CFrame.new(offset * Vector3.new(-1, 1, 1))).Position
end

local module = {}

function module.getVertices(cornerWedge: BasePart): { [number]: Vertex }
	local x = cornerWedge.Size.X / 2
	local y = cornerWedge.Size.Y / 2
	local z = cornerWedge.Size.Z / 2

	return {
		-- getWorldPosition(cornerWedge, Vector3.new(x, -y, z)),
		getWorldPosition(cornerWedge, Vector3.new(-x, -y, z)),

		getWorldPosition(cornerWedge, Vector3.new(x, -y, -z)),
		getWorldPosition(cornerWedge, Vector3.new(-x, -y, -z)),

		getWorldPosition(cornerWedge, Vector3.new(-x, y, -z)),
	}
end

function module.getLines(cornerWedge: BasePart): { [string]: Line }
	local x = cornerWedge.Size.X / 2
	local y = cornerWedge.Size.Y / 2
	local z = cornerWedge.Size.Z / 2

	return {
		swColumn = {
			getWorldPosition(cornerWedge, Vector3.new(-x, -y, -z)),
			getWorldPosition(cornerWedge, Vector3.new(-x, y, -z)),
		},
		sBorder = {
			getWorldPosition(cornerWedge, Vector3.new(x, -y, -z)),
			getWorldPosition(cornerWedge, Vector3.new(-x, -y, -z)),
		},
		wBorder = {
			getWorldPosition(cornerWedge, Vector3.new(-x, -y, -z)),
			getWorldPosition(cornerWedge, Vector3.new(-x, -y, z)),
		},
		eBorder = {
			getWorldPosition(cornerWedge, Vector3.new(x, -y, -z)),
			getWorldPosition(cornerWedge, Vector3.new(-x, -y, z)),
			-- getWorldPosition(cornerWedge, Vector3.new(x, -y, z)),
		},
		wTerrace = {
			getWorldPosition(cornerWedge, Vector3.new(-x, y, -z)),
			getWorldPosition(cornerWedge, Vector3.new(-x, -y, z)),
		},
		seColumn = {
			getWorldPosition(cornerWedge, Vector3.new(x, -y, -z)),
			getWorldPosition(cornerWedge, Vector3.new(-x, y, -z)),
		},
	}
end

function module.getSurfaces(meshPart: BasePart): {[Enum.NormalId]: Surface }
	local lines = module.getLines(meshPart)
	local opposite = meshPart.Size.Y

	local angle = math.atan2(opposite, meshPart.Size.Z)
	local angle2 = math.atan2(opposite, meshPart.Size.X)

	local vector = {
		Top = getSurfaceCFrame(meshPart, Vector3.new(0, 0, 1):Lerp(Vector3.new(0, 1, 0), math.cos(angle))).LookVector,
		Bottom = getSurfaceCFrame(meshPart, Vector3.new(0, -1, 0)).LookVector,
		Left = getSurfaceCFrame(meshPart, Vector3.new(1, 0, 0)).LookVector,
		Right = getSurfaceCFrame(meshPart, Vector3.new(-1, 0, 0):Lerp(Vector3.new(0, 1, 0), math.cos(angle2))).LookVector,
		Back = getSurfaceCFrame(meshPart, Vector3.new(0, 0, -1)).LookVector,
	}

	local surfaces: {[Enum.NormalId]: Surface } = {}
	for k, surfaceLineKeys in pairs({
		[normals.Top] = { "eBorder", "eTerrace", "wTerrace" }, --front
		[normals.Bottom] = { "sBorder", "eBorder", "wBorder" }, --bottom
		-- east = {"seColumn", "eBorder", "eTerrace"},
		[normals.Left] = { "swColumn", "wBorder", "wTerrace" },
		[normals.Back] = { "seColumn", "swColumn", "sBorder" },
	}) do
		local surfaceSpecificLines = {}
		for i, bondKey in pairs(surfaceLineKeys) do
			table.insert(surfaceSpecificLines, lines[bondKey])
		end
		surfaces[k] = {
			Normal = vector[k],
			Lines = surfaceSpecificLines,
		} :: Surface
	end

	return surfaces
end

return module
