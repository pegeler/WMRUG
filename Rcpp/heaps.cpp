// C++ program to print all permutations using Heap's algorithm
// 2 Dec 2017
// Reference:
// https://en.wikipedia.org/wiki/Heap%27s_algorithm
#include <bits/stdc++.h>
#include <stdio.h>
using namespace std;
 
void printArray(int a[],int n)
{
    for (int i=0; i<n; i++)
    {
        if (i < n - 1)
            cout << a[i] << " ";
	else
	    cout << a[i] << endl;
    }
}

void heaps_algorithm(int a[], int n)
{
    int c[n];
    
    for (int i=0; i<n; i++)
    {
        c[i] = 0;
    }
    
    printArray(a, n);
    
    int i=0;
    
    while (i<n)
    {
        if (c[i] < i)
	{
	    i & 1 ? swap(a[c[i]], a[i]) : swap(a[0], a[i]);
	    
	    printArray(a, n);
	    
	    c[i]++;
	    
	    i = 0;
	}
	
	else
	{
	    c[i] = 0;
	    i++;
	}
	
    }
}
 

int main(int argc, char *argv[])
{
    int n = argc - 1;
    int a[n];
    
        
    for (int i=0; i<n; i++) 
    {
        sscanf(argv[i + 1], "%i", &a[i]);;
    }
    
    heaps_algorithm(a, n);
    
    return 0;
}
