using System;
using System.Reflection;
using System.IO;
using Semmle.Extraction;
namespace Semmle.Extraction.CSharp
{
    /// <summary>
    /// A command-line driver for the extractor.
    /// </summary>
    public static class Driver
    {
        public static int Main(string[] args)
        {
            var assembly = Assembly.GetAssembly(typeof(Extractor));
            Console.WriteLine(assembly.GetName().Name);
            Console.WriteLine(assembly.GetName().Name);
            Console.WriteLine(string.Join("\n", assembly.GetManifestResourceNames()));
            // call GetManifestResourceStream("git-describe-all.log"), read stream and print it to the console
            Console.WriteLine(new StreamReader(assembly.GetManifestResourceStream("git-describe-all.log")).ReadToEnd());
            return -1;
            // Extractor.SetInvariantCulture();

            // return (int)Extractor.Run(args);
        }
    }
}
