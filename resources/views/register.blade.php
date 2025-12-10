<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CodeSprout Portal | Register</title>
    @vite('resources/css/app.css')
</head>
<body class="bg-gray-50 flex items-center justify-center min-h-screen">
    <div class="bg-white w-full max-w-md shadow-lg rounded-2xl p-8">
        <h1 class="text-2xl font-semibold text-gray-800 text-center mb-6">
           CodeSprout Portal
        </h1>
        <h2 class="text-lg font-medium text-gray-600 text-center mb-4">
            Create Your Account
        </h2>

        @if ($errors->any())
            <div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-3 mb-4 rounded">
                <ul class="list-disc ml-4 text-sm">
                    @foreach ($errors->all() as $error)
                        <li>{{ $error }}</li>
                    @endforeach
                </ul>
            </div>
        @endif

        <form action="{{ route('register') }}" method="POST" class="space-y-4">
            @csrf

            <div>
                <label class="block text-gray-700 text-sm font-medium mb-1">Full Name</label>
                <input type="text" name="name" class="w-full border-gray-300 rounded-lg shadow-sm focus:ring-blue-500 focus:border-blue-500" required>
            </div>

            <div>
                <label class="block text-gray-700 text-sm font-medium mb-1">Email Address</label>
                <input type="email" name="email" class="w-full border-gray-300 rounded-lg shadow-sm focus:ring-blue-500 focus:border-blue-500" required>
            </div>

            <div>
                <label class="block text-gray-700 text-sm font-medium mb-1">Password</label>
                <input type="password" name="password" class="w-full border-gray-300 rounded-lg shadow-sm focus:ring-blue-500 focus:border-blue-500" required>
            </div>

            <button type="submit" class="w-full bg-blue-600 text-white font-semibold py-2 rounded-lg shadow hover:bg-blue-700 transition">
                Register & Continue
            </button>
        </form>

        <p class="text-xs text-center text-gray-500 mt-6">
            © {{ date('Y') }} CodeSprout. All Rights Reserved.
        </p>
    </div>
</body>
</html>
