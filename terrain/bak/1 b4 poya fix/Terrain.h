//***********************************************************
//
// Name:		Terrain.H
// Last Update: 23/2/02
// Author:		Poya Manouchehri
//
// Description: CTerrain handles the terrain portion of the
//				engine. It holds open the file to the terrain
//				information, so terrain data can be loaded
//				dynamically. We use a ROAM method to render 
//				the terrain, ie using binary triangle trees.
//				The terrain consists of smaller PATCHS, which
//				do most of the work.
//
//***********************************************************

#ifndef TERRAIN_H
#define TERRAIN_H

#include <stdio.h>

#include "Patch.H"
#include "Vector3D.H"

extern bool g_HillShading;

class CTerrain
{
	public:
		CTerrain ();
		~CTerrain ();

		bool Initalize (char *filename);

//	protected:
		//the patches currently loaded
		CPatch				m_Patches[NUM_PATCHES_PER_SIDE][NUM_PATCHES_PER_SIDE];
		STerrainVertex		*m_pVertices;


//	protected:
		void CalcLighting();
		void SetNeighbors();
};

#endif