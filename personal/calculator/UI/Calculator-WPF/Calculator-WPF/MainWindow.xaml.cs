using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;

namespace Calculator_WPF
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
     public partial class MainWindow : Window
    {
        private const string DllFilePath = @"ExprEvaluator.dll";

        [DllImport(DllFilePath, CallingConvention = CallingConvention.Cdecl)]
        private extern static int Evaluate(byte[] expr, int len);
        [DllImport(DllFilePath, CallingConvention = CallingConvention.Cdecl)]
        private extern static double GetResult();


        public MainWindow()
        {
            InitializeComponent();
        }

        private void ComputeAndShow()
        {
            string expr = exprTextField.Text;
            // call assembly fucntion to compute the result.
            byte[] bexpr = System.Text.Encoding.ASCII.GetBytes(expr + '\0');
            int status = Evaluate(bexpr, expr.Length);

            string show = "";
            switch (status)
            {
                case 0:
                    double result = GetResult();
                    show = "=" + result.ToString();
                    break;
                case 1:
                    show = "Unmatched Parenthesis.";
                    break;
                case 2:
                    show = "Invalid Expression.";
                    break;
                case 3:
                    show = "Invalid Character.";
                    break;
                case 4:
                    show = "Divided Zero.";
                    break;
                case 5:
                    show = "Unsupported Function.";
                    break;
                case 6:
                    show = "Expression Too Long(Maximum 100).";
                    break;
            }
            resultLabel.Content = show;
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            ComputeAndShow();
        }

        private void ExprTextField_KeyDown(object sender, KeyEventArgs e)
        {
            if(e.Key == Key.Enter)
            {
                ComputeAndShow();
            }
        }
    }
}
