//***********************************************************
//
// Name:		Vector3D.Cpp
// Last Update:	28/1/02
// Author:		Poya Manouchehri
//
// Description: Provides an interface for a vector in R3 and
//				allows vector and scalar operations on it
//
//***********************************************************

#include "Vector3D.H"

CVector3D::CVector3D ()
{
	X = Y = Z = 0.0f;
}

CVector3D::CVector3D (float x, float y, float z)
{
	X = x;
	Y = y;
	Z = z;
}

int CVector3D::operator == (CVector3D &vector)
{
	if (X != vector.X ||
		Y != vector.Y ||
		Z != vector.Z)
		
		return 0;
	
	return 1;
}

int CVector3D::operator != (CVector3D &vector)
{
	if (X != vector.X ||
		Y != vector.Y ||
		Z != vector.Z)
		
		return 1;
	
	return 0;
}

int CVector3D::operator ! ()
{
	if (X != 0.0f ||
		Y != 0.0f ||
		Z != 0.0f)
		
		return 0;
	
	return 1;
}

//vector addition
CVector3D CVector3D::operator + (CVector3D &vector)
{
	CVector3D Temp;

	Temp.X = X + vector.X;
	Temp.Y = Y + vector.Y;
	Temp.Z = Z + vector.Z;

	return Temp;
}

//vector addition/assignment
CVector3D &CVector3D::operator += (CVector3D &vector)
{
	X += vector.X;
	Y += vector.Y;
	Z += vector.Z;

	return *this;
}

//vector subtraction
CVector3D CVector3D::operator - (CVector3D &vector)
{
	CVector3D Temp;

	Temp.X = X - vector.X;
	Temp.Y = Y - vector.Y;
	Temp.Z = Z - vector.Z;

	return Temp;
}

//vector subtrcation/assignment
CVector3D &CVector3D::operator -= (CVector3D &vector)
{
	X -= vector.X;
	Y -= vector.Y;
	Z -= vector.Z;

	return *this;
}

//scalar multiplication
CVector3D CVector3D::operator * (float value)
{
	CVector3D Temp;

	Temp.X = X * value;
	Temp.Y = Y * value;
	Temp.Z = Z * value;

	return Temp;
}

//scalar multiplication/assignment
CVector3D CVector3D::operator *= (float value)
{
	X *= value;
	Y *= value;
	Z *= value;

	return *this;
}

void CVector3D::Set (float x, float y, float z)
{
	X = x;
	Y = y;
	Z = z;
}

void CVector3D::Clear ()
{
	X = Y = Z = 0.0f;
}

//Dot product
float CVector3D::Dot (CVector3D &vector)
{
	return ( X * vector.X +
			 Y * vector.Y +
			 Z * vector.Z );
}

//Cross product
CVector3D CVector3D::Cross (CVector3D &vector)
{
	CVector3D Temp;

	Temp.X = (Y * vector.Z) - (Z * vector.Y);
	Temp.Y = (Z * vector.X) - (X * vector.Z);
	Temp.Z = (X * vector.Y) - (Y * vector.X);

	return Temp;
}

float CVector3D::GetLength ()
{
	return sqrtf ( SQR(X) + SQR(Y) + SQR(Z) );
}

void CVector3D::Normalize ()
{
	float scale = 1.0f/GetLength ();

	X *= scale;
	Y *= scale;
	Z *= scale;
}

SColor4ub CVector3D::ConvertToColor (float alpha_factor)
{
    SColor4ub color;

	color.R = (unsigned char)(127.0f * X + 128.0f);
	color.G = (unsigned char)(127.0f * Y + 128.0f);
	color.B = (unsigned char)(127.0f * Z + 128.0f);
	color.A = (unsigned char)(255.0f * alpha_factor);

	return color;
}