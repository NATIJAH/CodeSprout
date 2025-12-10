<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>CodeSprout Dashboard</title>
@vite('resources/css/app.css')
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body class="bg-gray-100 font-sans antialiased">
<div class="flex h-screen">
    <aside class="w-64 bg-white shadow-md flex flex-col">
        <div class="p-6 flex items-center space-x-3 border-b">
            <img src="{{ asset('images/team_logo.png') }}" alt="Logo" class="h-10 w-10 rounded-full">
            <h1 class="text-lg font-semibold text-gray-700">CodeSprout</h1>
        </div>
        <nav class="flex-1 p-4 space-y-2 text-gray-600">
            <a href="{{ url()->current() }}" class="flex items-center space-x-3 p-2 rounded-lg hover:bg-blue-50">Dashboard</a>
        </nav>
    </aside>
    <main class="flex-1 p-6 overflow-y-auto">
        <h1 class="text-2xl font-bold mb-4">@yield('page-title')</h1>
        <p class="text-gray-500 mb-6">@yield('page-subtitle')</p>
        @if(session('success'))
            <div class="bg-green-200 text-green-800 p-2 rounded mb-4">{{ session('success') }}</div>
        @endif
        @yield('content')
    </main>
</div>
</body>
</html>
